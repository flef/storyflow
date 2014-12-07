class Controller
  flow: null

  constructor: ->
    d3.json 'data.json', (data) =>
      blame_data = data.blame_data
      history_data = data.history_data
      link_data = data.link_data

      @flow = new HistoryFlow(blame_data, history_data.numberOfCommit)
      @sidebar = new Sidebar(history_data)
      @sankey = new SankeyFlow(link_data)
      
$ ->
  window.controller = new Controller
