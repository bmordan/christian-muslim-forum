const async = require('async')
const buildArticles = require('./articles')
const buildEvents = require('./events')
const buildPages = require('./pages')
const tasks = [buildPages, buildEvents, buildArticles]
const noop = err => {
  if (err) return console.error(err)
  console.log('Success! build tasks complete')
}
const build = done => async.series(tasks, done)
module.exports = build
// build(noop)
