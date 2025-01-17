use <catchnhole/catchnhole.scad>;
use <vitamins/v-slot.scad>;
use <vitamins/nema17.scad>;
include <vitamins/nema17-parameters.scad>;
include <parameters.scad>;
// How much of the Z extrusion we want to hold at the top corner. Measured in CAD.
z_hold_h = 20;

// How much of the top extrusion we want to hold at the top corner. Measured in CAD.
top_hold_w = 13;

// We want to move the stepper close to the extrusion (forward in Y axis)
// to save space. Calculate how close.
z_stepper_y_inset = (nema17_d - nema17_shaft_plate_fit_d) / 2;
z_stepper_bolt_l = stepper_bolt_l + stepper_mount_plate_t;

module z_stepper_mount () {
  difference () {
    nema17_mount_plate([
      nema17_chamfer,
      nema17_chamfer,
      z_belt_side() == -1 ? nema17_chamfer : 0,
      z_belt_side() == 1 ? nema17_chamfer : 0,
    ]);

    extrusion_side_bolt_inset = stepper_mount_plate_t - v_slot_wall_t;
    translate([ 0, 0, stepper_bolt_l + stepper_mount_plate_t ]) {
      nema17_mounts() {
        bolt(bolt, length = z_stepper_bolt_l);
        translate([ 0, 0, -extrusion_side_bolt_inset ]) bolt(
          bolt, kind = "countersunk", length = z_stepper_bolt_l,
          head_top_clearance = extrusion_side_bolt_inset
        );
        union() {
          if (z_belt_side() == -1)
            bolt(bolt, length = z_stepper_bolt_l);
        };
        union () {
          if (z_belt_side() == 1) 
            bolt(bolt, length = z_stepper_bolt_l);
        };
      }
    }
  }
}

module side_bolt_pair () {
  translate([0, -v_slot_d / 2, v_slot_d / 2]) rotate([90, 0, 0])
    bolt(frame_bolt, length = v_slot_wall_t);

  translate([0, v_slot_d / 2, v_slot_d / 2]) rotate([-90, 0, 0])
    bolt(frame_bolt, length = v_slot_wall_t);
}

function top_corner_stepper_x_offset () = -v_slot_d / 2 - (v_slot_wall_t - stepper_mount_plate_t);

module top_corner_to_stepper_mount () {
  translate([top_corner_stepper_x_offset(), 0, top_corner_h() - nema17_d / 2]) {
    to_z_belt_y_center() {
      rotate([-90, 0, 90])
        children();
    }
  }
}

// Top corner, `mirror([0, 1, 0])` to get the other one.
// Part is centered around the top of the Z extrusion.
module top_corner () {
  w = v_slot_wall_t + v_slot_d + frame_z_x_offset + top_hold_w;
  h = top_corner_h();
  l = v_slot_d + 2 * v_slot_wall_t;
  stepper_x_offset = top_corner_stepper_x_offset();

  difference () {
    union () {
      translate([-v_slot_wall_t - v_slot_d / 2, -v_slot_wall_t - v_slot_d / 2])
        cube([w, l, h]);

      // And finally hold the stepper.
      top_corner_to_stepper_mount()
        z_stepper_mount();
    }

    translate([0, 0, -z_v_slot_l + z_hold_h]) v_slot_clearance(h = z_v_slot_l);

    translate([0, 0, z_hold_h])
      bolt(frame_tap_bolt, length = v_slot_wall_t);

    translate([-v_slot_d / 2, 0, v_slot_d / 2]) rotate([0, -90, 0])
      bolt(frame_bolt, length = v_slot_wall_t);

    side_bolt_pair();

    translate([v_slot_d / 2 + frame_z_x_offset, 0]) {
      translate([0, 0, v_slot_d / 2]) rotate([0, 90, 0])
        v_slot_clearance(h = x_v_slot_l);

      translate([top_hold_w / 2, 0]) {
        translate([0, 0, z_hold_h])
          bolt(frame_bolt, length = v_slot_wall_t);

        side_bolt_pair();
      }
    }
  }

  // Add a support to the stepper mount plate to increase rigidity.
  translate([
    stepper_x_offset,
    z_belt_side() * (v_slot_d / 2 + v_slot_wall_t),
    h - stepper_mount_plate_t
  ]) {
    linear_extrude(stepper_mount_plate_t) {
      polygon([
        [0, 0],
        [0, z_belt_side() * nema17_d / 2],
        [nema17_d / 2, 0]
      ]);
    }
  }
}

// Y offset from the center of the Z extrusion to Y of the center of the belt path.
function z_belt_z_v_slot_y_offset () = v_slot_d / 2 + v_slot_wall_t + nema17_d / 2 - z_stepper_y_inset;
function z_belt_side () = sign(z_belt_z_v_slot_y_offset());

// Translates from the center of the Z extrusion to Y of the center of the belt path.
module to_z_belt_y_center () {
  translate([0, z_belt_z_v_slot_y_offset()]) children();
}

function top_corner_h () = z_hold_h + v_slot_wall_t;

mirror([1, 0, 0]) top_corner();
