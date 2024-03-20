import gleam/bool
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/javascript.{type Reference}
import gleam/list
import gleam/result
import plinth/browser/window
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
    happy: Bool,
    blink: Bool,
    game_state: GameState,
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
  SetHappy(Bool)
  SetBlink(Bool)
}

fn with_happy(model: Model) -> Model {
  javascript.set_reference(model.game_state.happy_playing, True)
  javascript.set_reference(model.game_state.happy_timer, 1000.0)
  Model(..model, happy: True)
}

type GameState {
  GameState(
    last_time: Reference(Float),
    happy_playing: Reference(Bool),
    happy_timer: Reference(Float),
    blink_playing: Reference(Bool),
    blink_timer: Reference(Float),
  )
}

fn animation(time, dispatch, game_state: GameState) {
  let dt = time -. javascript.dereference(game_state.last_time)
  javascript.set_reference(game_state.last_time, time)
  case javascript.dereference(game_state.happy_playing) {
    True -> {
      javascript.set_reference(
        game_state.happy_timer,
        javascript.dereference(game_state.happy_timer) -. dt,
      )
      case { javascript.dereference(game_state.happy_timer) <. 0.0 } {
        True -> {
          javascript.set_reference(game_state.happy_playing, False)
          dispatch(SetHappy(False))
        }
        _ -> Nil
      }
    }
    _ -> Nil
  }
  case javascript.dereference(game_state.blink_playing) {
    True -> {
      javascript.set_reference(
        game_state.blink_timer,
        javascript.dereference(game_state.blink_timer) -. dt,
      )
      case { javascript.dereference(game_state.blink_timer) <. 0.0 } {
        True -> {
          javascript.set_reference(game_state.blink_playing, False)
          dispatch(SetBlink(False))
        }
        _ -> Nil
      }
    }
    False ->
      case { javascript.dereference(game_state.happy_timer) <. 0.0 } {
        True -> Nil
        False -> {
          let chance = dt /. 4000.0
          let roll = float.random()
          case { roll <=. chance } {
            True -> {
              let blink_durations = [100.0, 100.0, 100.0, 500.0, 1000.0]
              let roll = int.random(5)
              javascript.set_reference(game_state.blink_playing, True)
              javascript.set_reference(
                game_state.blink_timer,
                blink_durations
                  |> list.at(roll)
                  |> result.unwrap(0.0),
              )
              dispatch(SetBlink(True))
              Nil
            }
            False -> Nil
          }
        }
      }
  }

  window.request_animation_frame(fn(time) {
    animation(time, dispatch, game_state)
  })
  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  let game_state =
    GameState(
      last_time: javascript.make_reference(0.0),
      happy_playing: javascript.make_reference(False),
      happy_timer: javascript.make_reference(0.0),
      blink_playing: javascript.make_reference(False),
      blink_timer: javascript.make_reference(0.0),
    )
  #(
    Model(
      sides: 5,
      angle: 0,
      pointiness: 5,
      convexiness_concaviness: 50,
      face_scale: 30,
      cassie: "no",
      can_lucy_me: True,
      happy: False,
      blink: False,
      game_state: game_state,
    ),
    effect.from(fn(dispatch) {
      window.request_animation_frame(fn(time) {
        animation(time, dispatch, game_state)
      })
      Nil
    }),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetSides(sides) ->
      case int.parse(sides) {
        Ok(sides) -> #(
          Model(..model, sides: sides)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetAngle(angle) ->
      case int.parse(angle) {
        Ok(angle) -> #(
          Model(..model, angle: angle)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetPointiness(pointiness) ->
      case int.parse(pointiness) {
        Ok(pointiness) -> #(
          Model(..model, pointiness: pointiness)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetConcavinessConvexiness(convexiness_concaviness) ->
      case int.parse(convexiness_concaviness) {
        Ok(convexiness_concaviness) -> #(
          Model(..model, convexiness_concaviness: convexiness_concaviness)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetFaceScale(face_scale) ->
      case int.parse(face_scale) {
        Ok(face_scale) -> #(
          Model(..model, face_scale: face_scale)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetCassie(answer) -> #(
      Model(..model, cassie: answer)
        |> with_happy,
      effect.none(),
    )
    SetCanLucyMe(_) -> {
      #(
        Model(..model, can_lucy_me: bool.negate(model.can_lucy_me))
          |> with_happy,
        effect.none(),
      )
    }
    SetHappy(happy) -> {
      #(Model(..model, happy: happy), effect.none())
    }
    SetBlink(blink) -> {
      #(Model(..model, blink: blink), effect.none())
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
