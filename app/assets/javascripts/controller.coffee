class Controller
  flow: null

  constructor: ->
    d3.json 'data.json', (data) =>
      blame_data = data.blame_data

      @flow = new HistoryFlow(blame_data)
      @commit_blocks = new CommitBlocks(blame_data)

$ ->
  window.controller = new Controller
