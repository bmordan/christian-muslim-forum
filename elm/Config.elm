module Config exposing (graphqlEndpoint, frontendUrl)


wordpressUrl : String
wordpressUrl =
    "http://api.christianmuslimforum.org"


graphqlEndpoint : String
graphqlEndpoint =
    wordpressUrl ++ "/graphql"


frontendUrl : String
frontendUrl =
    "http://www.christianmuslimforum.org"
