module Slides exposing (slides)

import Config exposing (frontendUrl)


src : String -> String
src svg =
    (frontendUrl ++ "/illustrations/" ++ svg ++ ".svg")


slides : List ( String, String )
slides =
    [ ( src "cmf"
      , "A forum is a meeting or medium where ideas and views on a particular issue can be exchanged."
      )
    , ( src "mitre"
      , "This is the Christan Muslim Forum. Launched in 2006 by the Archbishop of Canterbury"
      )
    , ( src "web"
      , "Our aim is to weave a web of open, honest and committed personal relationships between Christians and Muslims."
      )
    , ( src "search"
      , "On this site you will find a rich history of material. If you are looking for a particular topic you can use our search box."
      )
    , ( src "pointer"
      , "Select a story and start reading. At the bottom of the article, you will find links to related material. Follow the links, explore the conversation."
      )
    , ( src "forum"
      , "'Forum' articles are marked by this icon and include contributions on a topic from both Christian and Muslim writters. We think these are the most interesting. Look out for the icon."
      )
    , ( src "twitter"
      , "Follow us on Twitter and receive notifications when articles and events have been published."
      )
    , ( src "email"
      , "Subscribe to our mailing list and receive an email when articles and events have been published."
      )
    ]
