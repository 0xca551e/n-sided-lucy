import plinth/javascript/console
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

type Model {
  Model(greeting: String)
}

pub type Msg {
  Todo
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(greeting: "Hello world"),
    effect.from(fn(dispatch) { console.log("Hello world") }),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Todo -> todo
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.label([attribute.for("#sides")], [element.text("sides")]),
    html.input([attribute.id("sides"), attribute.type_("number")]),
    html.label([attribute.for("#angle")], [element.text("angle")]),
    html.div([], [element.text("0")]),
    html.input([attribute.id("angle"), attribute.type_("range")]),
    html.div([], [element.text("360")]),
    html.label([attribute.for("#pointiness")], [element.text("pointiness")]),
    html.div([], [element.text("bouba")]),
    html.input([attribute.id("pointiness"), attribute.type_("range")]),
    html.div([], [element.text("kiki")]),
    html.label([attribute.for("#concaviness-convexiness")], [
      element.text("pointiness"),
    ]),
    html.div([], [element.text("cavey")]),
    html.input([
      attribute.id("concaviness-convexiness"),
      attribute.type_("range"),
    ]),
    html.div([], [element.text("vexy")]),
    html.label([attribute.for("#face-scale")], [element.text("face")]),
    html.div([], [element.text("smol")]),
    html.input([attribute.id("face-scale"), attribute.type_("range")]),
    html.div([], [element.text("zoom")]),
    html.fieldset([], [
      html.legend([], [element.text("Cassie")]),
      html.input([
        attribute.id("no-cassie"),
        attribute.type_("radio"),
        attribute.name("cassie"),
      ]),
      html.label([attribute.for("no-cassie"), attribute.type_("radio")], [
        element.text("no thanks"),
      ]),
      html.input([
        attribute.id("yes-cassie"),
        attribute.type_("radio"),
        attribute.name("cassie"),
      ]),
      html.label([attribute.for("yes-cassie"), attribute.type_("radio")], [
        element.text("sure"),
      ]),
    ]),
    html.input([attribute.id("lucy-visible"), attribute.type_("checkbox")]),
    html.label([attribute.for("lucy-visible"), attribute.type_("checkbox")], [
      element.text("now lucy me"),
      {
        case True {
          True -> element.text("(now you don't)")
          False -> element.none()
        }
      },
    ]),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(dispatch) = lustre.start(app, "#app", Nil)

  dispatch
}
