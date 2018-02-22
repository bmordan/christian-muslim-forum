const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const Promise = require('bluebird')
const path = require('path')
const fs = require('fs')
const {execSync} = require('child_process')
const exec = Promise.promisifyAll(require('child_process').exec)
const stringReplaceStream = require('string-replace-stream')
const elmStaticHtml = require('elm-static-html-lib').elmStaticHtml
const { pipe, pipeP, assoc, tap, apply, contains } = require('ramda')

module.exports = function ({moduleName, distFolder, query, formatter, make}) {
  const elmRoot = path.join(__dirname, '..')
  const distRoot = path.join(__dirname, '..', 'dist')
  const fileName = moduleName === "Article" ? "article.html" : "index.html"
  const distPath = path.join(distRoot, distFolder, fileName)

  const formatResponse = (res) => {
    return pipe(
        formatter
        , assoc('headerModel', {scrollLeft: false})
        , assoc('footerModel', {modal: false, fname: "", lname: "", email: "", message: ""})
      )(res)
  }

  const addDecoder = (model) => {
    return {model: model, decoder: `${moduleName}.decodeModel`}
  }

  const generateHtml = (config) => {
    return elmStaticHtml(elmRoot, `${moduleName}.viewPage`, config)
      .catch(err => console.error(err))
  }

  const writeFile = (generatedHtml) => {
    let elmJsContent = `Elm.${moduleName}.embed(document.getElementById("elm-root"))`
    if (contains(moduleName, ['Articles'])) {
      elmJsContent += `;Elm.Search.embed(document.getElementById("search"))`
    }
    const html = generatedHtml.replace(`<script id="elm-js">`, `<script id="elm-js">${elmJsContent}`)
    fs.writeFileSync(distPath, html, "utf8")
    return html
  }

  const writeJs = () => {
    return execSync(make)
  }


  pipeP(
    request
    , formatResponse
    , addDecoder
    , generateHtml
    , writeFile
    , writeJs
  )(baseUrl, query)
}
