function init()
    shape = FindShape('deflectorCore')
end

function tick()
    local state = GetTagValue(shape, "state")
    if state == "true" then
        SetShapeEmissiveScale(shape, 1)
    else
        SetShapeEmissiveScale(shape, 0)
    end
    SetTag(shape, "state", false)
end