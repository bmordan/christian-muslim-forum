const {URL} = require('url')
const baseUrl = "http://46.101.6.182/graphql"
const location = new URL("http://christianmuslimforum.org")
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const he = require('he')
const { exec } = require('child_process')
const { multiple, elmStaticHtml } = require('elm-static-html-lib')
const { map, pipe, join, tap, prop, replace } = require('ramda')
const elmRoot = path.join(__dirname, '..')
const distRoot = path.join(__dirname, '..', 'dist')
global.document = global.document || {}
global.document.location = global.document.location || location

const query = cursor => `{
  posts(first: 100, after: "${cursor}"){
    pageInfo {
      hasNextPage
      endCursor
    }
    edges {
      node {
        title
        slug
        excerpt
        featuredImage {
          sourceUrl
        }
        date
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

const defaultConfig = {
  viewFunction: 'Article.viewPage',
  decoder: 'Article.decodeModel',
  indent: 0,
  newLines: false
}

const stripExcerpt = pipe(
  replace('<p>', ''),
  replace('</p>\n', ''),
  he.decode
)

const configArticleCreateFolder = ({node}) => {
  const { title, slug, excerpt, featuredImage, date } = node

  createFolder(path.join(__dirname, '..', 'dist', 'articles', slug))

  const article = {
    slug,
    title,
    excerpt: stripExcerpt(excerpt),
    content: "",
    date,
    author: {
      name: "",
      bio: "",
      avatar: { url: "" },
      faith: ""
    },
    featuredImage,
    commentCount: null,
    comments: {edges: [
      {
        node: {
          content: "",
          date: "",
          author: {
            name: "",
            bio: "",
            avatar: {url: ""},
            faith: ""
          }
        }
      }
    ]},
    tags: {edges: [{node: {slug}}]}
  }

  const model = {
    post: article,
    posts: [],
    related: [],
    prev: null,
    next: null,
    slug,
    comments: [],
    headerModel: {scrollLeft: false},
    footerModel: {modal: false, fname: "", lname: "", email: "", message: ""},
    searchModel: {term: "", currentTerm: "", tags: [], results: []}
  }

  return Object.assign({}, defaultConfig, {model, fileOutputName: slug})
}

let shouldGetMoreArticles = true
let cursor = null

const renderArticlesToHtml = ({posts}) => {
  const {pageInfo, edges} = posts

  shouldGetMoreArticles = pageInfo.hasNextPage
  cursor = pageInfo.endCursor

  const configs = map(configArticleCreateFolder, edges)

  return multiple(elmRoot, configs)
}

const writeFile = (generatedHtmls, resolve, reject) => {
  if (!generatedHtmls.length) return resolve()

  const { generatedHtml, fileOutputName } = generatedHtmls.pop()

  fs.writeFile(path.join(__dirname, '..', 'dist', 'articles', fileOutputName, 'index.html'), generatedHtml, (err) => {
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
    exec('elm-make ./elm/Article.elm --output ./dist/article.js --yes', (err) => {
      return err ? reject(err) : resolve()
    })
  })
}


function buildArticles (done) {
  if (!shouldGetMoreArticles) {
    shouldGetMoreArticles = true
    cursor = null
    console.log(new Date(), ' build articles done')
    return done()
  }

  request(baseUrl, query(cursor))
    .then(renderArticlesToHtml)
    .then(writeFilesToFolders)
    .then(writeJs)
    .then(() => buildArticles(done))
    .catch(err => console.error(err))
}

module.exports = buildArticles
