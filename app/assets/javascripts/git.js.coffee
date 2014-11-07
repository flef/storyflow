$ ->
  Prism.hooks.add 'after-highlight', (env) ->
    pre = env.element.parentNode

    return if (!pre || !/pre/i.test(pre.nodeName) || pre.className.indexOf('git-lines') is -1)

    linesNum = 1 + env.code.split('\n').length

    lines = new Array(linesNum)
    lines = lines.join("<span></span>")

    console.log lines

    lineNumbersWrapper = document.createElement('span')
    lineNumbersWrapper.className = 'line-numbers-rows'
    lineNumbersWrapper.innerHTML = lines
