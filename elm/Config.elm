module Config exposing (graphqlEndpoint, frontendUrl)


wordpressUrl : String
wordpressUrl =
    "https://christianmuslimforum.info"


graphqlEndpoint : String
graphqlEndpoint =
    wordpressUrl ++ "/graphql"


frontendUrl : String
frontendUrl =
    "https://www.christianmuslimforum.net"
