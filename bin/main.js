const build = require('./build')
const tasks = require('./tasks')
const { map } = require('ramda')

map(build, tasks)
