const build = require('./build')
const tasks = require('./tasks')
const { map } = require('ramda')

// map(build, tasks)
build(tasks[0]) // Home
// build(tasks[1]) // About
// build(tasks[2]) // Contact
// build(tasks[3]) // People
build(tasks[4]) // Events
// build(tasks[5]) // Article
