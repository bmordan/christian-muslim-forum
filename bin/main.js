const async = require('async')
const buildArticles = require('./articles')
const buildEvents = require('./events')
const buildPages = require('./pages')
const tasks = [buildPages, buildEvents, buildArticles]
const build = done => async.series(tasks, done)

module.exports = build

build(err => {
  if (err) return console.error(err)
  console.log(new Date(), ' Success! npm run build complete')
})
