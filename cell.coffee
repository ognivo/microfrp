IO =
  input:
    read : (elem) ->
      elem.value
    write: (elem, value) ->
      elem.value = value
  div:
    read : (elem) ->
      elem.textContent
    write: (elem, value) ->
      elem.textContent = value

class Cell
  constructor: (val) ->
    @deps_all = []
    @val      = val


  cell: (o) ->
    self = this
    val  = @val
    for key, cell of o
      do (key, cell) ->
        cell.depend (cell_val) ->
          val[key] = cell_val
          self.set(val)

  # depend: (dep_fn(val))
  # depend: (property_expression, {function} dep_fn(val))
  depend: (dep_fn) ->
    # add depender
    @deps_all.push(dep_fn)
    # init depender
    self = this
    setTimeout ->
      (dep_fn self.val)

  function: (val) ->
    val

  set: (val) ->
    val_transformed = @function(val)
    #
    if @set_raw
      @set_raw( val_transformed )
    #
    @val = val_transformed
    self = this
    if self.deps_all.length > 0
      setTimeout ->
        for dependant_fn in self.deps_all
          (dependant_fn val_transformed)
        return


class ElementCell extends Cell
  constructor: (element, opts = {val: null}) ->
    @element = element
    @set_io(element)
    super(opts.val)

  set_io: (input_element) ->
    @element = input_element
    @io =
      if 'INPUT' == input_element.tagName
        IO.input
      else
        IO.div

  set_raw: (val) ->
    @io.write( @element, val )


class UserInputSource extends ElementCell
  constructor: (input_element) ->
    super(input_element, {val:''})
    #
    @set( @io.read( input_element ) )
    #
    self = this
    self.element.addEventListener 'input', ->
      self.set( self.io.read( self.element ) )

  function: (val) ->
    '' == val && '0' || val

  set_raw: (val) ->
    @io.write( @element, val )


class TextCell extends ElementCell
  function: ({cella, cellb}) ->
    parseInt(cella) + parseInt(cellb)


class ImgCell extends ElementCell
  set_raw: ({src}) ->
    @element.src = src


# DEMO
ca = document.querySelector('.cell--a')
cb = document.querySelector('.cell--b')
cc = document.querySelector('.cell--c')
ci = document.querySelector('.cell--img')
#
input1    = new UserInputSource(ca)
input2    = new UserInputSource(cb)
#
text_cell = new TextCell(cc, {val: {cella: 0, cellb: 0}})
text_cell.cell(
  { cella: input1
  , cellb: input2 }
)
#
#img_cell  = new ImgCell(ci, {val: {}})
#img_cell.cell({src: input2})
