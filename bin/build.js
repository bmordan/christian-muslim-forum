const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const { execSync } = require('child_process')
const { elmStaticHtml } = require('elm-static-html-lib')
const { pipe, assoc, tap, apply, contains } = require('ramda')
const elmRoot = path.join(__dirname, '..')
const distRoot = path.join(__dirname, '..', 'dist')

module.exports = function ({moduleName, distFolder, query, formatter, make}, cb) {
  const fileName = moduleName === "Article" ? "article.html" : "index.html"
  const distPath = path.join(distRoot, distFolder, fileName)

  const formatResponse = (res) => {
    const model = pipe(
     formatter
      , assoc('headerModel', {scrollLeft: false})
      , assoc('footerModel', {modal: false, fname: "", lname: "", email: "", message: ""})
      , assoc('searchModel', {term: "", currentTerm: "", tags: [], results: []})
    )(res)
    return { model: model, decoder: `${moduleName}.decodeModel`, newLines: false, indent: 0 }
  }

  const writeFile = (generatedHtml) => {
    let elmJsContent = `Elm.${moduleName}.embed(document.getElementById("elm-root"))`
    const html = generatedHtml.replace(`<script id="elm-js">`, `<script id="elm-js">${elmJsContent}`)

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
    .then(() => cb(null, execSync(make)))
    .catch(err => cb(err))
}
