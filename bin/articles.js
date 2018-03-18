const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const { exec } = require('child_process')
const { multiple } = require('elm-static-html-lib')
const { map, pipe, join, tap, prop } = require('ramda')
const elmRoot = path.join(__dirname, '..')
const distRoot = path.join(__dirname, '..', 'dist')

const query = cursor => `{
  posts(first: 3, after: ${cursor}){
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
  fileOutputName: 'index.html',
  decoder: 'Article.decodeModel',
  indent: 0,
  newLines: false
}

const configArticle = ({node}) => {
  const { title, slug, excerpt, featuredImage, date } = node

  createFolder(slug)

  const article = {
    slug,
    title,
    excerpt,
    content: "",
    date,
    author: {
      name: "",
      bio: "",
      avatar: { url: "" },
      faith: ""
    },
    featuredImage,
    commentCount: 0,
    comments: {edges: []},
    tags: {edges: []}
  }

  const model = {
    post: article,
    posts: [],
    related: [],
    prev: "",
    next: "",
    slug,
    comments: [],
    headerModel: {scrollLeft: false},
    footerModel: {modal: false, fname: "", lname: "", email: "", message: ""},
    searchModel: {term: "", currentTerm: "", tags: [], results: []}
  }

  return Object.assign(defaultConfig, {model})
}

function buildArticles (cursor) {
  process.chdir(distRoot)

  createFolder('articles')

  request(baseUrl, query(cursor))
    .then(({posts}) => {
      process.chdir(path.join(distRoot, 'articles'))

      const {pageInfo, edges} = posts
      const configs = map(configArticle, edges)

      return multiple(elmRoot, configs)
    })
    .then(generatedHtmls => {
      console.log(generatedHtmls)
    })
    .catch(err => console.error(err))
}

buildArticles(null)
