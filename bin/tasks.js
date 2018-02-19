const {URL} = require('url')
const location = new URL("http://christianmuslimforum.org")

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
    }`,
    formatter: pipe(
      prop('pageBy')
      , pick(['title', 'content'])
      , assoc('skip', false)
    ),
    make: "elm-make ./elm/Home.elm --output ./dist/bundle.js"
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
    make: "elm-make ./elm/About.elm --output ./dist/about/bundle.js"
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
    make: "elm-make ./elm/Contact.elm --output ./dist/contact/bundle.js"
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
    make: "elm-make ./elm/People.elm --output ./dist/people/bundle.js"
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
    make: "elm-make ./elm/Articles.elm --output ./dist/articles/bundle.js"
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
    make: "elm-make ./elm/Article.elm --output ./dist/article.js"
  }
]

function formatArticle ({postBy}) {
  const {slug} = postBy
  return {
    post: null,
    posts: [],
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
