module Config exposing (graphqlEndpoint, frontendUrl)


wordpressUrl : String
wordpressUrl =
    "http://46.101.6.182"


graphqlEndpoint : String
graphqlEndpoint =
    wordpressUrl ++ "/graphql"


frontendUrl : String
frontendUrl =
    "http://localhost:3030"
