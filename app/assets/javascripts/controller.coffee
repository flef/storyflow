class Controller
  commit_blocks: []
  author_blocks: []
  flow: null

  constructor: ->
    d3.json 'data.json', (data) =>
      console.log data

      for blame in data.blame_data
        @commit_blocks.push(new CommitBlock(blame))

      @flow = new HistoryFlow(data)
      
      #for author, commits of data.author_data
        #@author_blocks.push(new AuthorBlock(author, commits))

      @putHTML()

  putHTML: ->
    @commit_blocks.forEach (c) ->
      $("#code_blocks").append(c.getHTML())

    #@author_blocks.forEach (a) ->
      #$("#sidebar").append(a.getHTML())

$ ->
  window.controller = new Controller
