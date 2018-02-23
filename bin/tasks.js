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
  , props
  , reduce
  , append
  , contains
  , filter
  , tap
  , map
  , head
  , assoc
  , objOf
} = require('ramda')


module.exports = [
  {
    moduleName: 'Home',
    distFolder: '.',
    query: `{
      pageBy(uri: "home") {
            title
            content
          }
      events(where: {status: FUTURE}){
        edges{
          node{
            slug
            title
            excerpt
            date
            featuredImage{
              sourceUrl
            }
          }
        }
      }
      posts(first: 4, after: null) {
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
        title
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
                }
              }
            }
          }
        }
      }
    }`,
    formatter: formatContact,
    make: "elm-make ./elm/People.elm --output ./dist/people/bundle.js --yes"
  },
  {
    moduleName: 'Articles',
    distFolder: 'articles',
    query: `{
      posts(first: 4, after: null) {
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
            }
            commentCount
          }
        }
      }
    }`,
    formatter: formatAtricles,
    make: "elm-make ./elm/Articles.elm --output ./dist/articles/bundle.js --yes"
  },
  {
    moduleName: 'Article',
    distFolder: '.',
    query: `{
      postBy(slug: "invitation-to-jerusalem") {
        id
        title
        slug
        date
        author {
          name
          description
          avatar {
            url
          }
        }
        featuredImage{
          sourceUrl
        }
        commentCount
        comments {
          edges {
            node {
              content
              date
              author {
                ... on User {
                  name
                  description
                  avatar {
                    url
                  }
                }
              }
            }
          }
        }
      }
    }`,
    formatter: formatArticle,
    make: "elm-make ./elm/Article.elm --output ./dist/article.js --yes"
  },
  {
    moduleName: 'Search',
    distFolder: 'search',
    query: `{
      tags(last: 20, where: {orderby: COUNT}){
        edges{
          node{
            slug
            count
          }
        }
      }
    }`,
    formatter: formatSearch,
    make: `elm-make ./elm/Search.elm --output ./dist/search.js --yes`
  }
]

function formatHome ({pageBy, events, posts, tags}) {
  const listEvent = events.edges.map(({node}) => {
    const {title, slug, date, excerpt, featuredImage} = node
    return {title, slug, date, excerpt, featuredImage}
  })
  const listArticle = posts.edges.map(({node}) => {
    const {title, slug, excerpt, featuredImage, commentCount, author} = node
    return {title, slug, excerpt, featuredImage, commentCount, author}
  })

  return {
    title: pageBy.title
    , content: pageBy.content
    , events: listEvent
  }
}

function formatArticle ({postBy}) {
  const {slug} = postBy
  return {
    post: null,
    posts: [],
    related: [],
    prev: null,
    next: null,
    slug: slug,
    commentCount: null,
    comments: []
  }
}

function formatAtricles ({posts}) {
  const {pageInfo, edges} = posts
  const formatted = {
    hasNextPage: pageInfo.hasNextPage
    , nextCursor: "null"
    , posts : edges
  }
  return formatted
}

function formatContact ({pageBy, people}) {
  const formatted = {
    content: pageBy.content,
    people: reduce(formatPerson, {}, people.edges)
  }
  return formatted
}

const arrayOfTags = pipe(
  prop('edges')
  , map(path(['node', 'slug']))
)

const getFaith = pipe(
  arrayOfTags
  , filter(contains(__, ['christian', 'muslim']))
  , head
)

function formatPerson (people, {node}) {
  const { title, content, featuredImage, categories } = node
  const person = {
    name: title,
    bio: content,
    avatar: prop('sourceUrl', featuredImage),
    faith: getFaith(categories),
    tags: arrayOfTags(categories)
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
