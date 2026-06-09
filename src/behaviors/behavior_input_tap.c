/*
 * Copyright (c) 2024 The ZMK Contributors
 *
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_behavior_input_tap

#include <zephyr/device.h>
#include <drivers/behavior.h>
#include <zephyr/input/input.h>
#include <zephyr/dt-bindings/input/input-event-codes.h>
#include <zephyr/logging/log.h>

#include <zmk/behavior.h>
#include <dt-bindings/zmk/pointing.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

#if DT_HAS_COMPAT_STATUS_OKAY(DT_DRV_COMPAT)

struct behavior_input_tap_config {
    uint16_t x_code;
    uint16_t y_code;
};

static int on_keymap_binding_pressed(struct zmk_behavior_binding *binding,
                                     struct zmk_behavior_binding_event event) {
    const struct device *behavior_dev = zmk_behavior_get_binding(binding->behavior_dev);
    const struct behavior_input_tap_config *cfg = behavior_dev->config;

    int16_t x = MOVE_X_DECODE(binding->param1);
    int16_t y = MOVE_Y_DECODE(binding->param1);

    LOG_DBG("position %d dx %d dy %d", event.position, x, y);

    if (x != 0) {
        input_report_rel(behavior_dev, cfg->x_code, x, (y == 0), K_NO_WAIT);
    }
    if (y != 0) {
        input_report_rel(behavior_dev, cfg->y_code, y, true, K_NO_WAIT);
    }

    return 0;
}

static int on_keymap_binding_released(struct zmk_behavior_binding *binding,
                                      struct zmk_behavior_binding_event event) {
    return 0;
}

static const struct behavior_driver_api behavior_input_tap_driver_api = {
    .binding_pressed = on_keymap_binding_pressed,
    .binding_released = on_keymap_binding_released,
};

#define BIT_INST(n)                                                                                \
    static const struct behavior_input_tap_config behavior_input_tap_config_##n = {                \
        .x_code = DT_INST_PROP_OR(n, x_input_code, INPUT_REL_X),                                   \
        .y_code = DT_INST_PROP_OR(n, y_input_code, INPUT_REL_Y),                                   \
    };                                                                                             \
    BEHAVIOR_DT_INST_DEFINE(n, NULL, NULL, NULL, &behavior_input_tap_config_##n, POST_KERNEL,      \
                            CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                                   \
                            &behavior_input_tap_driver_api);

DT_INST_FOREACH_STATUS_OKAY(BIT_INST)

#endif /* DT_HAS_COMPAT_STATUS_OKAY(DT_DRV_COMPAT) */
