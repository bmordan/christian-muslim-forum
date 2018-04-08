const pages = require('./tasks')
const build = require('./build')

function buildPages (pages, done) {
  if (!pages.length) {
    pages = require('./tasks')
    console.log('build pages done')
    return done()
  }

  build(pages.pop(), (err, msg) => {
    if (err) throw err
    buildPages(pages, done)
  })
}

module.exports = done => buildPages(pages, done)
