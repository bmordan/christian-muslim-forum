const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const { exec } = require('child_process')
const { elmStaticHtml } = require('elm-static-html-lib')
const { pipe, assoc, tap, apply, contains } = require('ramda')
const addGoogleAnalytics = require('./gtag')
const elmRoot = path.join(__dirname, '..')
const distRoot = path.join(__dirname, '..', 'dist')

module.exports = function ({moduleName, distFolder, query, formatter, make}, done) {
  const fileName = moduleName === "Article" ? "article.html" : "index.html"
  const distPath = path.join(distRoot, distFolder, fileName)

  const formatResponse = (res) => {
    const model = pipe(
     formatter
      , assoc('headerModel', {showMenu: false})
      , assoc('searchModel', {term: "", currentTerm: "", tags: [], results: []})
    )(res)
    return { model: model, decoder: `${moduleName}.decodeModel`, newLines: false, indent: 0 }
  }

  const writeFile = (generatedHtml) => {
    let elmJsContent = `Elm.${moduleName}.embed(document.getElementById("elm-root"))`
    let html = generatedHtml.replace(`<script id="elm-js">`, `<script id="elm-js">${elmJsContent}`)
    html = addGoogleAnalytics(html)

    return new Promise(function (resolve, reject) {
      fs.writeFile(distPath, html, "utf8", (err) => {
        if (err) return reject(err)
        return resolve()
      })
    })
  }

  request(baseUrl, query)
    .then(res => elmStaticHtml(elmRoot, `${moduleName}.viewPage`, formatResponse(res)))
    .then(html => writeFile(html))
    .then(exec.bind(null, make, done))
    .catch(err => done(err))
}
