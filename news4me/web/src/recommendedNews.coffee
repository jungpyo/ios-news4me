bridge = null
articles = []
userId = null
accessToken = null
shownArticleIds = []


rivets.bind document.getElementById('articles'),
  articles: articles


connectWebViewJavascriptBridge = (callback) ->
  if window.WebViewJavascriptBridge
    callback WebViewJavascriptBridge
  else
    document.addEventListener 'WebViewJavascriptBridgeReady'
    ,
      ->
        callback WebViewJavascriptBridge
    ,
      false

connectWebViewJavascriptBridge (currentBridge) ->
  bridge = currentBridge

  bridge.init (message, responseCallback) ->
    if message is 'loadMore'
      loadArticles()

  bridge.send 'init', (result) ->
    userId = result.userId
    accessToken = result.accessToken
    loadArticles()


$(document).on 'ajaxSuccess', (xhr, options, data) ->
  # alert 'ajaxSuccess'

$(document).on 'ajaxError', (xhr, options, error) ->
  alert 'ajaxError'


loadArticles = ->
  apiUrl = "#{baseUrl}/news/facebook/#{userId}?accessToken=#{accessToken}"

  $.getJSON apiUrl, (currentArticles) ->
    for article in currentArticles
      do (article) ->
        article.onTap = (e) ->
          bridge.send
            message: 'onTapArticle'
            articleUrl: article.articleUrl
            articleId: article.id

      article.pubDate = new Date article.pubDate
      d = article.pubDate
      article.pubDateString = "#{d.getFullYear()}년 #{d.getMonth()+1}월 #{d.getDate()}일 #{d.getHours()}시 #{d.getMinutes()}분"

      article.hasImage = false
      if article.imageUrls?[0]?
        article.imageUrl = article.imageUrls[0]
        article.hasImage = true

      article.relatedKeywords = article.words.join ', '

      articles.push article

    bridge.send 'onArticlesLoaded'


notifyShownArticle = (articleId, callback) ->
  apiUrl = "#{baseUrl}/articles/#{articleId}/show/from/facebook/#{userId}"

  $.get apiUrl, (data) ->
    callback null, data  if callback?


window.onscroll = (e) ->
  bodyTag = $('body')
  articleIdTags = $('.article .id')

  articleIdTags.each (index, item) ->
    articleIdTag = articleIdTags.eq(index)
    articleId = articleIdTag.text()
    articleIdTagTop = articleIdTag.parent().offset().top
    
    return  if articleId in shownArticleIds

    if articleIdTagTop < bodyTag.scrollTop()
      shownArticleIds.push articleId
      notifyShownArticle articleId
