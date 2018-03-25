const build = require('./build')
const tasks = require('./tasks')
const buildArticles = require('./articles')

function buildTasks (tasks) {
  if (!tasks.length) return buildArticles(true, null)

  build(tasks.pop(), (err, msg) => {
    if (err) throw err
    buildTasks(tasks)
  })
}

buildTasks(tasks)

// const cb = () => console.log('done')

// build(tasks[0], cb) // Home
// build(tasks[1], cb) // About
// build(tasks[2], cb) // Contact
// build(tasks[3], cb) // People
// build(tasks[4], cb) // Events
// build(tasks[5], cb) // Article
