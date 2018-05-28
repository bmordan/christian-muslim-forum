const {URL} = require('url')
const baseUrl = "http://46.101.6.182/graphql"
const location = new URL("http://christianmuslimforum.org")
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const he = require('he')
const { exec } = require('child_process')
const { multiple, elmStaticHtml } = require('elm-static-html-lib')
const { map, pipe, join, tap, prop, replace, evolve, partial } = require('ramda')
const elmRoot = path.join(__dirname, '..')
const distRoot = path.join(__dirname, '..', 'dist')
global.document = global.document || {}
global.document.location = global.document.location || location

const date = new Date()
const year = date.getYear() -100 + 2000
const month = date.getMonth() + 1
const day = date.getDate()

const query = `{
  events(where: {status: FUTURE, dateQuery: {
    after: {
      day: ${day},
      month: ${month},
      year: ${year}
    }
  }}){
    edges {
      node {
        title
        slug
        excerpt
        content
        date
        featuredImage {
          sourceUrl
        }
      }
    }
  }
}`

const getFolderNames = pipe(map(({node}) => node.slug), join(' '))

const execute = (cmd) => {
  return new Promise(function (resolve, reject) {
    exec(cmd, (err, stdout, stderr) => {
      return err ? reject(err, stdout, stderr) : resolve(stdout, stderr)
    })
  })
}

const createFolder = dir => fs.existsSync(dir) || fs.mkdirSync(dir)

const stripExcerpt = pipe(
  replace('<p>', ''),
  replace('</p>\n', ''),
  he.decode
)

const createConfig = (events, event) => {
  const slug = event.node.slug

  createFolder(path.join(__dirname, '..', 'dist', 'events', slug))

  const transform = {
    excerpt: stripExcerpt
  }

  const model = {
    events: events.map(pipe(evolve(transform), prop('node'))),
    event: slug,
    year: null,
    month: null,
    day: null,
    headerModel: {scrollLeft: false},
    footerModel: {modal: false, fname: "", lname: "", email: "", message: ""},
    searchModel: {term: "", currentTerm: "", tags: [], results: []}
  }

  const defaultConfig = {
    viewFunction: 'Event.viewPage',
    decoder: 'Event.decodeModel',
    indent: 0,
    newLines: false
  }

  return Object.assign({}, defaultConfig, {model, fileOutputName: slug})
}

const renderHtmls = ({events}) => {
  const configs = map(partial(createConfig, [events.edges]), events.edges)
  return multiple(elmRoot, configs)
}

const writeFile = (generatedHtmls, resolve, reject) => {
  if (!generatedHtmls.length) return resolve()

  const { generatedHtml, fileOutputName } = generatedHtmls.pop()

  fs.writeFile(path.join(__dirname, '..', 'dist', 'events', fileOutputName, 'index.html'), generatedHtml, (err) => {
    if (err) return reject(err)
    return writeFile(generatedHtmls, resolve, reject)
  })
}

const writeFilesToFolders = (generatedHtmls) => {
  return new Promise(function (resolve, reject) {
    return writeFile(generatedHtmls, resolve, reject)
  })
}

const writeJs = () => {
  return new Promise(function (resolve, reject) {
    exec('elm-make ./elm/Event.elm --output ./dist/events/bundle.js --yes', (err) => {
      return err ? reject(err) : resolve()
    })
  })
}


module.exports = function buildEvents (done) {
  request(baseUrl, query)
    .then(renderHtmls)
    .then(writeFilesToFolders)
    .then(writeJs)
    .then(() => {
      console.log(new Date(), ' build events done')
      return done()
    })
    .catch(err => console.error(err))
}
