module Config exposing (graphqlEndpoint, frontendUrl)


wordpressUrl : String
wordpressUrl =
    "http://localhost:8000"


graphqlEndpoint : String
graphqlEndpoint =
    wordpressUrl ++ "/graphql"


frontendUrl : String
frontendUrl =
    "http://localhost:3000"
