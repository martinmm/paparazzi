/*
 * Copyright (C) 2017 The Paparazzi team
 *
 * This file is part of paparazzi
 *
 * paparazzi is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * paparazzi is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with paparazzi; see the file COPYING.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

/**
 * @file "modules/meteo/wind_align.c"
 *
 */

// Downlink
#ifndef DOWNLINK_DEVICE
#define DOWNLINK_DEVICE DOWNLINK_AP_DEVICE
#endif
#include "pprzlink/messages.h"
#include "subsystems/datalink/downlink.h"

#ifndef WIND_ALIGN_PGAIN
#define WIND_ALIGN_PGAIN 0.005
#endif

#define WIND_ALIGN_PERIODIC_FREQ_INT ((int)WIND_ALIGN_PERIODIC_FREQ)

float heading;

void wind_align_init(void) {

  struct FloatEulers *att = stateGetNedToBodyEulers_f();

  heading = att->phi;
}

void wind_align_periodic(void) {

  static float phi_ring[WIND_ALIGN_PERIODIC_FREQ_INT] = { 0 }, phi_sum = 0, phi_filt;
  struct FloatEulers *att = stateGetNedToBodyEulers_f();
  uint16_t ptr = 0, i;

  phi_ring[ptr] = att->phi;
  for (i = 0; i < WIND_ALIGN_PERIODIC_FREQ_INT; i++)
    phi_sum += phi_ring[i];
  if (++ptr == WIND_ALIGN_PERIODIC_FREQ_INT)
    ptr = 0;
  phi_filt = DegOfRad(phi_sum / WIND_ALIGN_PERIODIC_FREQ_INT);
  phi_filt = DegOfRad(att->phi);

  heading += (WIND_ALIGN_PGAIN) * phi_filt;

//  uint16_t head = (uint16_t) heading + 180;
//  RunOnceEvery(WIND_ALIGN_PERIODIC_FREQ_INT, DOWNLINK_SEND_TMP_STATUS(DefaultChannel, DefaultDevice, &head, &phi_filt));

  if (heading > 360) {
    heading = 0;
  }

  nav_set_heading_rad(RadOfDeg(heading));
}
