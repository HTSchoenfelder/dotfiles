hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.workspace_rule({
    workspace = "1",
    layout = "monocle"
})
hl.workspace_rule({
    workspace = "2",
    layout = "dwindle"
})

hl.bind(
    mainMod .. " + M",
    hl.dsp.layout("cyclenext")
)