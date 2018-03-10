const baseUrl = "http://46.101.6.182/graphql"
const request = require('graphql-request').request
const path = require('path')
const fs = require('fs')
const {execSync} = require('child_process')
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
        , assoc('searchModel', {term: "", currentTerm: "", tags: [], results: []})
      )(res)
  }

  const addDecoder = (model) => {
    return {model: model, decoder: `${moduleName}.decodeModel`}
  }

  const generateHtml = (config) => {
    return elmStaticHtml(elmRoot, `${moduleName}.viewPage`, config)
      .catch(err => console.error(err))
  }


  const updateOpenGraphTags = ({title, description, image, url}) => {
    const decodeTitle = document.createElement('div');decodeTitle.innerHTML = title;
    const decodeDescription = document.createElement('div');decodeDescription.innerHTML = description.replace(/[<p></p>]/g, "");
    document.getElementById("og:title").setAttribute("content", decodeTitle.innerHTML)
    document.getElementById("og:description").setAttribute("content", decodeDescription.innerHTML)
    document.getElementById("og:image").setAttribute("content", image)
    document.getElementById("og:url").setAttribute("content", url)
  }

  const writeFile = (generatedHtml) => {
    let elmJsContent = `const App = Elm.${moduleName}.embed(document.getElementById("elm-root"))`
    if (moduleName === 'Article') {
      elmJsContent += `;App.ports.toOpenGraphTags.subscribe(${updateOpenGraphTags.toString()});`
    }
    const html = generatedHtml.replace(`<script id="elm-js">`, `<script id="elm-js">${elmJsContent}`)
    fs.writeFileSync(distPath, html, "utf8")
    return
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
