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
]

function formatContact ({pageBy, people}) {
  const formatted = {
    content: pageBy.content,
    people: reduce(formatPerson, {}, people.edges)
  }
  return formatted
}

function formatPerson (people, {node}) {
  const { title, content, featuredImage, categories } = node
  const getFaith = pipe(
    prop('edges')
    , map(path(['node', 'slug']))
    , filter(contains(__, ['christian', 'muslim']))
    , head
  )
  const person = {
    name: title,
    bio: content,
    avatar: prop('sourceUrl', featuredImage),
    faith: getFaith(categories)
  }
  return append(person, people)
}
