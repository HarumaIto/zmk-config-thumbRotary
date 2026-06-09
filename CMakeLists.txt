# Copyright (c) 2024 The ZMK Contributors
# SPDX-License-Identifier: MIT

if(CONFIG_ZMK_BEHAVIOR_INPUT_TAP)
  zephyr_library()
  zephyr_library_sources(src/behaviors/behavior_input_tap.c)
endif()
