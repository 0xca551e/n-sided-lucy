import plinth/javascript/console
import lustre
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
  html.h1([], [element.text(model.greeting)])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(dispatch) = lustre.start(app, "#app", Nil)

  dispatch
}
