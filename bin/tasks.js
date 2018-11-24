const {URL} = require('url')
const location = new URL("http://christianmuslimforum.org")
const nodepath = require('path')

// this mocks the document.location object for server side rendering of Article page
global.document = global.document || {}
global.document.location = global.document.location || location

const {
  pipe
  , __
  , pick
  , prop
  , path
  , tap
  , reduce
  , append
  , contains
  , filter
  , map
  , head
  , assoc
  , objOf
} = require('ramda')

const date = new Date()
const year = date.getYear() -100 + 2000
const month = date.getMonth() + 1
const day = date.getDate()

module.exports = [
  {
    moduleName: 'Home',
    distFolder: '.',
    query: `{
      pageBy(uri: "home") {
            title
            content
            featuredImage{
              sourceUrl
            }
          }
      events(where: {status: FUTURE}){
        edges{
          node{
            slug
            title
            excerpt
            content
            date
            featuredImage{
              sourceUrl
            }
          }
        }
      }
      articles: posts(first: 4, after: null) {
            pageInfo{
              hasNextPage
              endCursor
            }
            edges{
              node{
                slug
                title
                excerpt
                featuredImage{
                  sourceUrl
                }
                author{
                  name
                  avatar{
                    url
                  }
                  bio: description
                  faith: nickname
                }
                commentCount
              }
            }
          }
      tags(last: 20, where: {orderby: COUNT}){
        edges{
          node{
            slug
            count
          }
        }
      }
    }`,
    formatter: formatHome,
    make: `elm-make ./elm/Home.elm --output ./dist/bundle.js --yes`
  },
  {
    moduleName: 'About',
    distFolder: 'about',
    query: `{
      pageBy(uri: "about-us") {
        content
      }
    }`,
    formatter: pipe(
      prop('pageBy')
      , pick(['content'])
    ),
    make: "elm-make ./elm/About.elm --output ./dist/about/bundle.js --yes"
  },
  {
    moduleName: 'Resources',
    distFolder: 'resources',
    query: `{
      pageBy(uri: "resources") {
        content
      }
    }`,
    formatter: pipe(
      prop('pageBy')
      , pick(['content'])
    ),
    make: "elm-make ./elm/Resources.elm --output ./dist/resources/bundle.js --yes"
  },
  {
    moduleName: 'Contact',
    distFolder: 'contact',
    query: `{
      pageBy(uri: "contact"){
        content
      }
      people(where: {categoryName: "staff"}){
        edges{
          node{
            title
            content
            featuredImage{
              sourceUrl
            }
            categories{
              edges{
                node{
                  slug
                }
              }
            }
          }
        }
      }
    }`,
    formatter: formatContact,
    make: "elm-make ./elm/Contact.elm --output ./dist/contact/bundle.js --yes"
  },
  {
    moduleName: 'People',
    distFolder: 'people',
    query: `{
      pageBy(uri: "people"){
        content
      }
      people{
        edges{
          node{
            title
            content
            featuredImage{
              sourceUrl
            }
            categories{
              edges{
                node{
                  slug
                  name
                }
              }
            }
          }
        }
      }
    }`,
    formatter: formatContact,
    make: "elm-make ./elm/People.elm --output ./dist/people/bundle.js --yes"
  }
]

const listEvent = map(({node}) => {
  const {title, slug, date, excerpt, content, featuredImage} = node
  return {title, slug, date, excerpt, content, featuredImage}
})

const listArticle = map(({node}) => {
  const {title, slug, excerpt, featuredImage, commentCount, author} = node
  return {title, slug, excerpt, featuredImage, commentCount, author}
})

function formatHome ({pageBy, events, articles, tags}) {
  return {
    title: pageBy.title
    , content: pageBy.content
    , featuredImage: pageBy.featuredImage
    , events: listEvent(events.edges)
    , articles: listArticle(articles.edges)
    , articlesMore: true
    , articlesNext: "null"
    , year: null
    , month: null
    , day: null
  }
}


function formatContact ({pageBy, people}) {
  return {
    content: pageBy.content,
    people: reduce(formatPerson, {}, people.edges)
  }
}

const arrayOfTags = pipe(
  prop('edges')
  , map(path(['node', 'slug']))
)

const getFaith = pipe(
  arrayOfTags
  , filter(contains(__, ['christian', 'muslim', 'buddhist']))
  , head
)

function formatPerson (people, {node}) {
  const { title, content, featuredImage, categories } = node
  const person = {
    name: title,
    bio: content,
    avatar: prop('sourceUrl', featuredImage),
    faith: getFaith(categories),
    tags: []
  }
  return append(person, people)
}

function formatSearch ({tags}) {
  return pipe(
   prop('edges')
   , map(({node}) => ({slug: node.slug, count: node.count}))
   , objOf('tags')
   , assoc('term', "")
   , assoc('currentTerm', "")
   , assoc('results', [])
 )(tags)
}

function formatEvents ({events}) {
  return {
    events: listEvent(events.edges),
    year: null,
    month: null,
    day: null
  }
}
