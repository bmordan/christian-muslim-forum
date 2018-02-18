const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const Promise = require('bluebird')
const path = require('path')
const fs = Promise.promisifyAll(require('fs'))
const exec = Promise.promisifyAll(require('child_process').exec)
const stringReplaceStream = require('string-replace-stream')
const elmStaticHtml = require('elm-static-html-lib').elmStaticHtml
const { pipe, pipeP, assoc } = require('ramda')

module.exports = function ({moduleName, distFolder, query, formatter, make}) {
  const elmRoot = path.join(__dirname, '..')
  const distRoot = path.join(__dirname, '..', 'dist')
  const distPath = path.join(distRoot, distFolder, 'index.html')

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
  }

  const writeFile = (generatedHtml) => {
    const elmJsContent = `Elm.${moduleName}.embed(document.getElementById("elm-root"))`
    const html = generatedHtml.replace(`<script id="elm-js">`, `<script id="elm-js">${elmJsContent}`)
    return fs.writeFileAsync(distPath, html)
      .catch(err => console.error(err))
  }

  const promiseFromChildProcess = (child) => {
      return new Promise(function (resolve, reject) {
          child.addListener("error", reject)
          child.addListener("exit", resolve)
      })
  }

  const writeJs = () => {
    const child = exec(make)
    return promiseFromChildProcess(child)
      .catch(err => console.error(err))
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
