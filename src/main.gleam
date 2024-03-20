import gleam/bool
import gleam/dynamic
import gleam/int
import plinth/javascript/console
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

type Model {
  Model(
    sides: Int,
    angle: Int,
    pointiness: Int,
    convexiness_concaviness: Int,
    face_scale: Int,
    cassie: String,
    can_lucy_me: Bool,
  )
}

pub type Msg {
  SetSides(String)
  SetAngle(String)
  SetPointiness(String)
  SetConcavinessConvexiness(String)
  SetFaceScale(String)
  SetCassie(String)
  SetCanLucyMe(String)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(
      sides: 5,
      angle: 0,
      pointiness: 5,
      convexiness_concaviness: 50,
      face_scale: 30,
      cassie: "no",
      can_lucy_me: True,
    ),
    effect.from(fn(dispatch) { console.log("Hello world") }),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetSides(sides) ->
      case int.parse(sides) {
        Ok(sides) -> #(Model(..model, sides: sides), effect.none())
        _ -> #(model, effect.none())
      }
    SetAngle(angle) ->
      case int.parse(angle) {
        Ok(angle) -> #(Model(..model, angle: angle), effect.none())
        _ -> #(model, effect.none())
      }
    SetPointiness(pointiness) ->
      case int.parse(pointiness) {
        Ok(pointiness) -> #(
          Model(..model, pointiness: pointiness),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetConcavinessConvexiness(convexiness_concaviness) ->
      case int.parse(convexiness_concaviness) {
        Ok(convexiness_concaviness) -> #(
          Model(..model, convexiness_concaviness: convexiness_concaviness),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetFaceScale(face_scale) ->
      case int.parse(face_scale) {
        Ok(face_scale) -> #(
          Model(..model, face_scale: face_scale),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetCassie(answer) -> #(Model(..model, cassie: answer), effect.none())
    SetCanLucyMe(_) -> {
      #(
        Model(..model, can_lucy_me: bool.negate(model.can_lucy_me)),
        effect.none(),
      )
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  console.log(model)
  html.div([], [
    html.div([], [
      html.label([attribute.for("#sides")], [element.text("sides")]),
      html.input([
        attribute.id("sides"),
        attribute.type_("number"),
        attribute.value(dynamic.from(model.sides)),
        event.on_input(SetSides),
      ]),
    ]),
    html.div([], [
      html.label([attribute.for("#angle")], [element.text("angle")]),
      html.input([
        attribute.id("angle"),
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("359"),
        attribute.step("1"),
        attribute.value(dynamic.from(model.angle)),
        event.on_input(SetAngle),
      ]),
      html.span([], [element.text(int.to_string(model.angle))]),
    ]),
    html.div([], [
      html.label([attribute.for("#pointiness")], [element.text("pointiness")]),
      html.input([
        attribute.id("pointiness"),
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("100"),
        attribute.step("1"),
        attribute.value(dynamic.from(model.pointiness)),
        event.on_input(SetPointiness),
      ]),
      html.span([], [
        element.text({
          case model.pointiness {
            0 -> "bouba"
            100 -> "kiki"
            n -> int.to_string(n)
          }
        }),
      ]),
    ]),
    html.div([], [
      html.label([attribute.for("#concaviness-convexiness")], [
        element.text("concaviness/convexiness"),
      ]),
      html.input([
        attribute.id("concaviness-convexiness"),
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("100"),
        attribute.step("1"),
        attribute.value(dynamic.from(model.convexiness_concaviness)),
        event.on_input(SetConcavinessConvexiness),
      ]),
      html.span([], [
        element.text({
          case model.convexiness_concaviness {
            0 -> "cavey"
            100 -> "yes"
            n -> int.to_string(n)
          }
        }),
      ]),
    ]),
    html.div([], [
      html.label([attribute.for("#face-scale")], [element.text("face")]),
      html.input([
        attribute.id("face-scale"),
        attribute.type_("range"),
        attribute.min("1"),
        attribute.max("100"),
        attribute.step("1"),
        attribute.value(dynamic.from(model.face_scale)),
        event.on_input(SetFaceScale),
      ]),
      html.span([], [
        element.text({
          case model.face_scale {
            1 -> "smol"
            100 -> "yes"
            n -> int.to_string(n)
          }
        }),
      ]),
    ]),
    html.div([], [
      html.fieldset([], [
        html.legend([], [element.text("Cassie")]),
        html.input([
          attribute.id("no-cassie"),
          attribute.type_("radio"),
          attribute.name("cassie"),
          attribute.value(dynamic.from("no")),
          attribute.checked(model.cassie == "no"),
          event.on_input(SetCassie),
        ]),
        html.label([attribute.for("no-cassie"), attribute.type_("radio")], [
          element.text("no thanks"),
        ]),
        html.input([
          attribute.id("yes-cassie"),
          attribute.type_("radio"),
          attribute.name("cassie"),
          attribute.value(dynamic.from("yes")),
          attribute.checked(model.cassie == "yes"),
          event.on_input(SetCassie),
        ]),
        html.label([attribute.for("yes-cassie"), attribute.type_("radio")], [
          element.text("sure"),
        ]),
      ]),
    ]),
    html.div([], [
      html.input([
        attribute.id("lucy-visible"),
        attribute.type_("checkbox"),
        attribute.checked(model.can_lucy_me),
        event.on_input(SetCanLucyMe),
      ]),
      html.label([attribute.for("lucy-visible"), attribute.type_("checkbox")], [
        element.text("now lucy me"),
        {
          case model.can_lucy_me {
            False -> element.text("(now you don't)")
            True -> element.none()
          }
        },
      ]),
    ]),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(dispatch) = lustre.start(app, "#app", Nil)

  dispatch
}
