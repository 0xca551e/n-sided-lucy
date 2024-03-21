import gleam/bool
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/javascript.{type Reference}
import gleam/list
import gleam/pair
import gleam/string
import gleam/result
import plinth/browser/window
import plinth/javascript/console
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event

@external(javascript, "./external.js", "downloadSvg")
fn download_svg(selector: String) -> Nil

@external(javascript, "./external.js", "pi")
fn pi() -> Float

@external(javascript, "./external.js", "sin")
fn sin(x: Float) -> Float

@external(javascript, "./external.js", "cos")
fn cos(x: Float) -> Float

fn scale(point: #(Float, Float), scalar: Float) -> #(Float, Float) {
  #(point.0 *. scalar, point.1 *. scalar)
}

fn lerp(v0: Float, v1: Float, t: Float) {
  v0 +. t *. { v1 -. v0 }
}

fn lerp2d(v0: #(Float, Float), v1: #(Float, Float), t: Float) {
  #(lerp(v0.0, v1.0, t), lerp(v0.1, v1.1, t))
}

fn cycle_left(l: List(a)) -> List(a) {
  l
  |> list.drop(1)
  |> list.append(list.take(l, 1))
}

fn every_even(l: List(a)) -> List(a) {
  l
  |> list.index_fold([], fn(acc, x, i) {
    acc
    |> list.append(case int.is_odd(i) {
      True -> [x]
      False -> []
    })
  })
}

fn every_odd(l: List(a)) -> List(a) {
  l
  |> list.index_fold([], fn(acc, x, i) {
    acc
    |> list.append(case int.is_even(i) {
      True -> [x]
      False -> []
    })
  })
}

type Model {
  Model(
    sides: Int,
    angle: Int,
    pointiness: Int,
    arm_ratio: Float,
    eye_distance: Int,
    eye_height: Int,
    mouth_size: Int,
    mouth_height: Int,
    face_scale: Int,
    cassie: String,
    can_lucy_me: Bool,
    happy: Bool,
    blink: Bool,
    game_state: GameState,
  )
}

pub type Msg {
  Reset
  DownloadSvg
  SetSides(String)
  SetAngle(String)
  SetPointiness(String)
  SetArmRatio(String)
  SetEyeDistance(String)
  SetEyeHeight(String)
  SetMouthSize(String)
  SetMouthHeight(String)
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

fn reset() -> Model {
  let game_state =
    GameState(
      last_time: javascript.make_reference(0.0),
      happy_playing: javascript.make_reference(False),
      happy_timer: javascript.make_reference(0.0),
      blink_playing: javascript.make_reference(False),
      blink_timer: javascript.make_reference(0.0),
    )
  Model(
    sides: 5,
    angle: 288,
    pointiness: 50,
    arm_ratio: 0.7,
    face_scale: 100,
    eye_distance: 35,
    eye_height: 50,
    mouth_size: 8,
    mouth_height: 55,
    cassie: "no",
    can_lucy_me: True,
    happy: False,
    blink: False,
    game_state: game_state,
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model = reset()
  #(
    model,
    effect.from(fn(dispatch) {
      window.request_animation_frame(fn(time) {
        animation(time, dispatch, model.game_state)
      })
      Nil
    }),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Reset -> #(
      Model(..reset(), game_state: model.game_state)
        |> with_happy,
      effect.none(),
    )
    DownloadSvg -> #(model, effect.from(fn(_) { download_svg("#lucy-svg") }))
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
    SetArmRatio(arm_ratio) ->
      case float.parse(arm_ratio) {
        Ok(arm_ratio) -> #(
          Model(..model, arm_ratio: arm_ratio)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetEyeDistance(eye_distance) ->
      case int.parse(eye_distance) {
        Ok(eye_distance) -> #(
          Model(..model, eye_distance: eye_distance)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetEyeHeight(eye_height) ->
      case int.parse(eye_height) {
        Ok(eye_height) -> #(
          Model(..model, eye_height: eye_height)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetMouthSize(mouth_size) ->
      case int.parse(mouth_size) {
        Ok(mouth_size) -> #(
          Model(..model, mouth_size: mouth_size)
            |> with_happy,
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    SetMouthHeight(mouth_height) ->
      case int.parse(mouth_height) {
        Ok(mouth_height) -> #(
          Model(..model, mouth_height: mouth_height)
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

fn eye() -> Element(Msg) {
  svg.circle([
    attribute.attribute("cx", "0.0"),
    attribute.attribute("cy", "0.0"),
    attribute.attribute("r", "4.0"),
    attribute.attribute("fill", "#151515"),
    attribute.attribute("stroke", "none"),
  ])
}

fn happy_eye(flip: Bool) -> Element(Msg) {
  let eye =
    svg.polyline([
      attribute.attribute("points", "-2,-2.67 2,0 -2,2.67"),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "#151515"),
      attribute.attribute("stroke-width", "4px"),
      attribute.attribute("stroke-linecap", "round"),
    ])
  case flip {
    True -> svg.g([attribute.attribute("transform", "rotate(180)")], [eye])
    False -> eye
  }
}

fn blink_eye() -> Element(Msg) {
  svg.line([
    attribute.attribute("x1", "-4"),
    attribute.attribute("y1", "0"),
    attribute.attribute("x2", "4"),
    attribute.attribute("y2", "0"),
    attribute.attribute("stroke", "#151515"),
    attribute.attribute("stroke-width", "2px"),
    attribute.attribute("stroke-linecap", "round"),
  ])
}

fn eyes(
  distance: Int,
  eye_height: Int,
  happy: Bool,
  blink: Bool,
) -> Element(Msg) {
  let offset = int.to_float(distance) /. 2.0
  let height = 50 - eye_height
  svg.g(
    [
      attribute.attribute(
        "transform",
        [
            "translate(0,",
            height
              |> int.to_string(),
            ")",
          ]
          |> string.join(""),
      ),
    ],
    [
      svg.g(
        [
          attribute.attribute(
            "transform",
            [
                "translate(-",
                offset
                  |> float.to_string(),
                ",0)",
              ]
              |> string.join(""),
          ),
        ],
        [
          case happy, blink {
            True, _ -> happy_eye(False)
            _, True -> blink_eye()
            _, _ -> eye()
          },
        ],
      ),
      svg.g(
        [
          attribute.attribute(
            "transform",
            [
                "translate(",
                offset
                  |> float.to_string(),
                ",0)",
              ]
              |> string.join(""),
          ),
        ],
        [
          case happy, blink {
            True, _ -> happy_eye(True)
            _, True -> blink_eye()
            _, _ -> eye()
          },
        ],
      ),
    ],
  )
}

fn mouth(distance: Int, height: Int) -> Element(Msg) {
  let offset = distance / 2
  let height = height - 50
  svg.g(
    [
      attribute.attribute(
        "transform",
        [
            "translate(0,",
            height
              |> int.to_string(),
            ")",
          ]
          |> string.join(""),
      ),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          [
              "M -",
              offset
                |> int.to_string(),
              " 0 A 0.01 0.01 0 0 0 ",
              offset
                |> int.to_string(),
              " 0",
            ]
            |> string.join(""),
        ),
        attribute.attribute("fill", "none"),
        attribute.attribute("stroke", "#151515"),
        attribute.attribute("stroke-width", "4px"),
        attribute.attribute("stroke-linecap", "round"),
      ]),
    ],
  )
}

fn view(model: Model) -> Element(Msg) {
  let form =
    html.div([attribute.class("form")], [
      html.h2([], [element.text("n-sided lucy!")]),
      html.div([attribute.class("form__grid")], [
        html.label([attribute.for("#sides")], [element.text("sides")]),
        html.input([
          attribute.id("sides"),
          attribute.type_("number"),
          attribute.value(dynamic.from(model.sides)),
          event.on_input(SetSides),
        ]),
        html.div([], []),
        //
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
        html.div([], [element.text(int.to_string(model.angle))]),
        //
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
        html.div([], [
          element.text({
            case model.pointiness {
              0 -> "bouba"
              100 -> "kiki"
              n -> int.to_string(n)
            }
          }),
        ]),
        //
        html.label([attribute.for("#arm-ratio")], [element.text("arm ratio")]),
        html.input([
          attribute.id("arm-ratio"),
          attribute.type_("range"),
          attribute.min("0"),
          attribute.max("10"),
          attribute.step("0.1"),
          attribute.value(dynamic.from(model.arm_ratio)),
          event.on_input(SetArmRatio),
        ]),
        html.div([], [
          element.text({
            case model.arm_ratio {
              x if x <=. 0.1 -> "kirby"
              x if x >=. 9.5 -> "long long lucy"
              x -> float.to_string(x)
            }
          }),
        ]),
        //
        html.label([attribute.for("#eye-distance")], [
          element.text("eye distance"),
        ]),
        html.input([
          attribute.id("eye-distance"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("100"),
          attribute.step("1"),
          attribute.value(dynamic.from(model.eye_distance)),
          event.on_input(SetEyeDistance),
        ]),
        html.div([], [
          element.text({
            case model.eye_distance {
              100 -> "derp"
              n -> int.to_string(n)
            }
          }),
        ]),
        //
        html.label([attribute.for("#eye-height")], [element.text("eye height")]),
        html.input([
          attribute.id("eye-height"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("100"),
          attribute.step("1"),
          attribute.value(dynamic.from(model.eye_height)),
          event.on_input(SetEyeHeight),
        ]),
        html.div([], [element.text(int.to_string(model.eye_height))]),
        //
        html.label([attribute.for("#mouth-size")], [element.text("mouth size")]),
        html.input([
          attribute.id("mouth-size"),
          attribute.type_("range"),
          attribute.min("0"),
          attribute.max("100"),
          attribute.step("1"),
          attribute.value(dynamic.from(model.mouth_size)),
          event.on_input(SetMouthSize),
        ]),
        html.div([], [
          element.text(case model.mouth_size {
            0 -> "but i must scream"
            n -> int.to_string(n)
          }),
        ]),
        //
        html.label([attribute.for("#mouth-height")], [
          element.text("mouth height"),
        ]),
        html.input([
          attribute.id("mouth-height"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("100"),
          attribute.step("1"),
          attribute.value(dynamic.from(model.mouth_height)),
          event.on_input(SetMouthHeight),
        ]),
        html.div([], [element.text(int.to_string(model.mouth_height))]),
        //
        html.label([attribute.for("#face-scale")], [element.text("face")]),
        html.input([
          attribute.id("face-scale"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("200"),
          attribute.step("1"),
          attribute.value(dynamic.from(model.face_scale)),
          event.on_input(SetFaceScale),
        ]),
        html.div([], [
          element.text({
            case model.face_scale {
              1 -> "smol"
              200 -> "beeg"
              n -> int.to_string(n)
            }
          }),
        ]),
      ]),
      html.div([], [
        html.fieldset([], [
          html.legend([], [element.text("cassie")]),
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
          html.br([]),
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
        html.label(
          [attribute.for("lucy-visible"), attribute.type_("checkbox")],
          [
            element.text("now lucy me"),
            {
              case model.can_lucy_me {
                False -> element.text(" (now you don't)")
                True -> element.none()
              }
            },
          ],
        ),
      ]),
      html.div([attribute.class("form__grid-buttons")], [
        html.button([event.on_click(DownloadSvg)], [element.text("download")]),
        html.button([event.on_click(Reset)], [element.text("reset")]),
      ]),
    ])

  let angle_between_arms_radians = { pi() *. 2.0 } /. int.to_float(model.sides)
  let arm_angles =
    list.range(0, model.sides - 1)
    |> list.map(int.to_float)
    |> list.map(fn(i) { angle_between_arms_radians *. i })
  let pit_angles =
    arm_angles
    |> list.map(fn(x) { x +. angle_between_arms_radians /. 2.0 })
  let arm_points =
    arm_angles
    |> list.map(fn(angle) {
      #(cos(angle), sin(angle))
      |> scale(50.0)
    })
  let pit_points =
    pit_angles
    |> list.map(fn(angle) {
      #(cos(angle), sin(angle))
      |> scale(50.0 /. { model.arm_ratio +. 1.0 })
    })
  let lines =
    [arm_points, pit_points]
    |> list.interleave()
    |> list.window_by_2()
    |> list.append([
      #(
        list.last(pit_points)
          |> result.unwrap(#(0.0, 0.0)),
        list.first(arm_points)
          |> result.unwrap(#(0.0, 0.0)),
      ),
    ])
    |> list.map(fn(line) {
      let t1 = int.to_float(100 - model.pointiness) /. 100.0 *. 0.5
      let t2 = 1.0 -. t1
      #(lerp2d(line.0, line.1, t1), lerp2d(line.0, line.1, t2))
    })
  let start_lines = every_odd(lines)
  let end_lines = every_even(lines)
  let segments =
    [
      start_lines
        |> list.map(pair.first),
      start_lines
        |> list.map(pair.second),
      pit_points,
      end_lines
        |> list.map(pair.first),
      end_lines
        |> list.map(pair.second),
      arm_points
        |> cycle_left(),
    ]
    |> list.interleave()
    |> list.sized_chunk(6)
  let segment_commands =
    segments
    |> list.map(fn(x) {
      case x {
        [a1, a2, b, c1, c2, d] ->
          string.join(
            [
              // "L",
                a1
                |> pair.first()
                |> float.to_string(),
              a1
                |> pair.second()
                |> float.to_string(),
              "L",
              a2
                |> pair.first()
                |> float.to_string(),
              a2
                |> pair.second()
                |> float.to_string(),
              "Q",
              b
                |> pair.first()
                |> float.to_string(),
              b
                |> pair.second()
                |> float.to_string(),
              c1
                |> pair.first()
                |> float.to_string(),
              c1
                |> pair.second()
                |> float.to_string(),
              "L",
              c2
                |> pair.first()
                |> float.to_string(),
              c2
                |> pair.second()
                |> float.to_string(),
              "Q",
              d
                |> pair.first()
                |> float.to_string(),
              d
                |> pair.second()
                |> float.to_string(),
            ],
            " ",
          )
        _ -> ""
      }
    })
    |> string.join(" ")
  let first_point =
    start_lines
    |> list.first()
    |> result.map(pair.first)
    |> result.unwrap(#(0.0, 0.0))
  let full_command =
    [
      "M",
      segment_commands,
      first_point
        |> pair.first()
        |> float.to_string(),
      first_point
        |> pair.second()
        |> float.to_string(),
      "Z",
    ]
    |> string.join(" ")
  let lucy =
    html.div([attribute.class("lucy")], [
      html.svg(
        [
          attribute.id("lucy-svg"),
          attribute.attribute("viewBox", "0 0 100 100"),
          attribute.attribute("width", "90%"),
          attribute.attribute("height", "90%"),
          attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
          attribute.style([
            #("visibility", case model.can_lucy_me {
              True -> "visible"
              False -> "hidden"
            }),
          ]),
        ],
        [
          svg.g(
            [
              attribute.attribute(
                "transform",
                [
                    "translate(50,50) ",
                    "rotate(",
                    model.angle
                      |> int.to_string(),
                    ")",
                  ]
                  |> string.join(""),
              ),
            ],
            [
              svg.path([
                attribute.attribute("d", full_command),
                attribute.attribute("stroke", "#151515"),
                attribute.attribute("stroke-width", "4px"),
                attribute.attribute("fill", {
                  case model.cassie {
                    "yes" -> "#ca551e"
                    _ -> "#ffaff3"
                  }
                }),
              ]),
              svg.g(
                [
                  attribute.attribute(
                    "transform",
                    [
                        "scale(",
                        model.face_scale
                          |> int.to_float()
                          |> float.divide(100.0)
                          |> result.unwrap(1.0)
                          |> float.to_string(),
                        ")",
                      ]
                      |> string.join(""),
                  ),
                ],
                [
                  svg.g([attribute.attribute("transform", "rotate(90)")], [
                    eyes(
                      model.eye_distance,
                      model.eye_height,
                      model.happy,
                      model.blink,
                    ),
                  ]),
                  svg.g([attribute.attribute("transform", "rotate(90)")], [
                    case model.mouth_size {
                      0 -> element.none()
                      x -> mouth(x, model.mouth_height)
                    },
                  ]),
                ],
              ),
            ],
          ),
        ],
      ),
    ])
  html.div([attribute.class("app")], [
    lucy,
    html.img([attribute.class("waves-small"), attribute.src("/waves.svg")]),
    html.img([
      attribute.class("waves-large"),
      attribute.src("/waves-vertical.svg"),
    ]),
    form,
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(dispatch) = lustre.start(app, "#app", Nil)

  dispatch
}
