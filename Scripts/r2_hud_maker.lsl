//*********************************************************************************
//**   This program is free software: you can redistribute it and/or modify
//**   it under the terms of the GNU Affero General Public License as
//**   published by the Free Software Foundation, either version 3 of the
//**   License, or (at your option) any later version.
//**
//**   This program is distributed in the hope that it will be useful,
//**   but WITHOUT ANY WARRANTY; without even the implied warranty of
//**   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//**   GNU Affero General Public License for more details.
//**
//**   You should have received a copy of the GNU Affero General Public License
//**   along with this program.  If not, see <https://www.gnu.org/licenses/>
//*********************************************************************************

// v3.0 02Apr2020 <seriesumei@avimail.org> - Based on ss-r from Control/Serie Sumei
// v3.1 05May2020 <seriesumei@avimail.org> -  Merge Ruth2 and Roth2 alpha HUD creation

// This builds a multi-paned HUD for Ruth/Roth that includes the existing
// alpha HUD mesh (for Ruth) or a new alpha HUD (for Roth) and adds panes
// for a new skin applier and an Options pane that has fingernail
// shape/colorand toenail color buttons (for Ruth) as well as hand and foot
// pose buttons (for both).
//
// To build the HUD from scratch you will need to:
// * Create a new empty box prim named 'Object'
// * Take a copy of the new box into inventory and leave the original on the ground
// * Rename the box on the ground "HUD maker"
// * Copy the following objects into the inventory of the new box:
//   * the new box created above (from inventory) named 'Object'
//   * the button meshes: '4x1_outline_button', '5x1-s_button' and '6x1_button'
//   * the r2_hud_maker.lsl script (this script)
// * Take a copy of the HUD maker box because trying again is much simpler from
//   this stage than un-doing what the script is about to do
// * Light fuse (touch the box prim) and get away, the new HUD will be
//   assembled around the box prim which will become the root prim of the HUD.
// * Remove this script and the other objects from the HUD root prim and copy
//   in the HUD script(s).
// * The other objects are also not needed any longer in the root prim and
//   can be removed.

// Which HUD to build?
integer ROTH = FALSE;

vector build_pos;
integer link_me = FALSE;
integer FINI = FALSE;
integer counter = 0;
integer num_repeat = 0;

key hud_texture;
key header_texture;
key skin_texture;
key options_texture;
key fingernails_shape_texture;
key alpha_button_texture;
key alpha_doll_texture;

vector bar_size = <0.4, 0.4, 0.03>;
vector hud_size = <0.4, 0.4, 0.34985>;
vector color_button_size = <0.01, 0.145, 0.025>;
vector shape_button_size = <0.01, 0.295, 0.051>;
vector alpha_button_scale = <0.25, 0.125, 0.0>;

vector alpha_hud_pos;
vector alpha_doll_pos;
float alpha_button_left_offset;
float alpha_button_right_offset;

list alpha_button_pos = [
    <-0.2085, 0.6225, 0.12>,
    <-0.2085, 0.7475, 0.12>,
    <-0.2085, 0.6225, -0.12>,
    <-0.2085, 0.7475, -0.12>
];

list hand_button_pos = [
    <-0.2085, -0.7202, -0.0708>,
    <-0.2085, -0.7202, 0.0305>,
    <-0.2085, -0.7202, 0.1316>,
    <-0.2085, -0.7452, -0.0708>,
    <-0.2085, -0.7452, 0.0305>,
    <-0.2085, -0.7452, 0.1316>
];

// Vertical offset for alpha button textures
list alpha_button_voffset = [
    0.4375, 0.3125, 0.1875, 0.0625, -0.0625, -0.1875, -0.3125, -0.4375
];

// Spew debug info
integer VERBOSE = FALSE;

// Hack to detect Second Life vs OpenSim
// Relies on a bug in llParseString2List() in SL
// http://grimore.org/fuss/lsl/bugs#splitting_strings_to_lists
integer is_SL() {
    string sa = "12999";
//    list OS = [1,2,9,9,9];
    list SL = [1,2,999];
    list la = llParseString2List(sa, [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    return (la == SL);
}

// Wrapper for osGetGridName to simplify transition between environments
string GetGridName() {
    string grid_name;
    // Comment out this line to run in SecondLife, un-comment it to run in OpenSim
    grid_name = osGetGridName();
    if (is_SL()) {
        grid_name = llGetEnv("sim_channel");
    }
    llOwnerSay("grid: " + grid_name);
    return grid_name;
}

// The textures used in the HUD referenced below are included in the repo:
// hud_texture: ruth2_v3_hud_gradient.png
// header_texture: ruth2_v3_hud_header.png
// skin_texture: ruth2_v3_hud_skin.png
// options_texture: ruth2_v3_hud_options.png
// alpha_button_texture: r2_hud_alpha_buttons.png
// alpha_doll_texture: r2_hud_alpha_doll.png
// fingernails_shape_texture: ruth 2.0 hud fingernails shape.png

get_textures() {
    if (ROTH) {
        alpha_button_left_offset = 0.125;
        alpha_button_right_offset = 0.375;
    } else {
        alpha_button_left_offset = -0.375;
        alpha_button_right_offset = -0.125;
    }
    if (is_SL()) {
        // Textures in SL
        // The textures listed are full-perm uploaded by seriesumei Resident
        hud_texture = "7fc1e90b-b940-6e9f-aed9-85888a0a1eb3";
        skin_texture = "206804f6-908a-8efb-00de-fe00b2604906";
        alpha_button_texture = "97e894f2-aee2-a479-0fa8-49d049bfb718";
        alpha_doll_texture = "f7d81224-3b66-081c-21a8-eab787e8e9a7";
        if (ROTH) {
            header_texture = "c54a2e5d-398e-2c1d-77ab-5353a20cbc23";
            options_texture = "43ec4359-6750-8c8a-4098-c8f79243eb25";
        } else {
            header_texture = "c74e2f3e-d493-47e7-0042-58c240802c8a";
            options_texture = "3857c5e8-95aa-1731-d27c-8ca3baa98d0b";
            fingernails_shape_texture = "fb6ee827-3c3e-99a8-0e33-47015c0845a9";
            alpha_hud_pos = <0.0, 1.03528, 0.24976>;
        }
        alpha_doll_pos = <0.0, 0.57, 0.18457>;
    } else {
        if (GetGridName() == "OSGrid") {
            // Textures in OSGrid
            // TODO: Bad assumption that OpenSim == OSGrid, how do we detect
            //       which grid?  osGetGridName() is an option but does not
            //       compile in SL so editing the script would stll be required.
            //       Maybe we don't care too much about that?
            // The textures listed are full-perm uploaded by serie sumei to OSGrid
            hud_texture = "2eee6e1a-66c5-4209-92b4-171820d5cfa5";
            skin_texture = "64184dac-b33b-4a1b-b200-7d09d8928b64";
            alpha_button_texture = "4e97068e-7570-47c2-af2f-e7965c5d5078";
            alpha_doll_texture = "831b6b63-6934-4db7-9473-9058e0410e17";
            if (ROTH) {
                header_texture = "0bd02931-21e8-4b81-90d1-aca4349c0679";
                options_texture = "e89ff0c8-03a4-410d-bf0a-1352610cb701";
            } else {
                header_texture = "2d80dac8-670a-4f46-8201-e7796a77afdd";
                options_texture = "a97c448b-10a7-4a2c-a705-f9b73368c852";
                fingernails_shape_texture = "fe777245-4fa2-4834-b794-0c29fa3e1fcf";
                alpha_hud_pos = <0.0, 0.811, 0.0>;
            }
            alpha_doll_pos = <-0.22416, 0.7, 0.0>;
        } else {
            log("OpenSim detected but grid " + GetGridName() + " unknown, using blank textures");
            hud_texture = TEXTURE_BLANK;
            header_texture = TEXTURE_BLANK;
            skin_texture = TEXTURE_BLANK;
            options_texture = TEXTURE_BLANK;
            fingernails_shape_texture = TEXTURE_BLANK;
            alpha_button_texture = TEXTURE_BLANK;
            alpha_doll_texture = TEXTURE_BLANK;
        }
    }
}

log(string txt) {
    if (VERBOSE) {
        llOwnerSay(txt);
    }
}

rez_object(string name, vector delta, vector rot) {
    log("Rezzing " + name);
    llRezObject(
        name,
        build_pos + delta,
        <0.0, 0.0, 0.0>,
        llEuler2Rot(rot),
        0
    );
}

configure_header(string name, float offset_y) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TEXTURE, ALL_SIDES, header_texture, <1.0, 0.08, 0.0>, <0.0, offset_y, 0.0>, 0.0,
        PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_TEXTURE, 5, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_SIZE, bar_size
    ]);
}

configure_color_buttons(string name) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
        PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
        PRIM_SIZE, color_button_size
    ]);
}

configure_outline_button(string name, vector size, vector taper, vector scale, vector offset) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, <0.0, 1.0, 0.0>, 0.0, ZERO_VECTOR, taper, ZERO_VECTOR,
        PRIM_TEXTURE, 0, skin_texture, scale, offset, 0.0,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_SIZE, size
    ]);

}

default {
    touch_start(integer total_number) {
        get_textures();
        build_pos = llGetPos();
        counter = 0;
        // set up root prim
        log("Configuring root");
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_NAME, "HUD base",
            PRIM_SIZE, <0.1, 0.1, 0.1>,
            PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0,0,0>, <0.0, 0.455, 0.0>, 0.0,
            PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00
        ]);

        // See if we'll be able to link to trigger build
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm) {
        // Only bother rezzing the object if will be able to link it.
        if (perm & PERMISSION_CHANGE_LINKS) {
            // log("Rezzing south");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.16, -0.5>, <0.0, 0.0, 0.0>);
        } else {
            llOwnerSay("unable to link objects, aborting build");
        }
    }

    object_rez(key id) {
        counter++;
        integer i = llGetNumberOfPrims();
        log("counter="+(string)counter);

        if (link_me) {
            llCreateLink(id, TRUE);
            link_me = FALSE;
        }

        if (counter == 1) {
            configure_header("minbar", 0.440);
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_TEXTURE, 2, header_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_TEXTURE, 4, header_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_SIZE, <0.40, 0.08, 0.03>
            ]);

        // ***** Alpha HUD *****

            log("Rezzing alphabar (west)");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.5, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 2) {
            configure_header("alphabar", 0.312);

            log("Rezzing alpha HUD");
            link_me = TRUE;
            if (ROTH) {
                rez_object("Object", <0.0, 0.6894, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
            } else {
                rez_object("alpha-hud", alpha_hud_pos, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
            }
        }
        else if (counter == 3) {
            log("Configuring alpha HUD");
            if (ROTH) {
                llSetLinkPrimitiveParamsFast(2, [
                    PRIM_NAME, "alphabox",
                    PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                    PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                    PRIM_SIZE, hud_size
                ]);

                log("Rezzing alpha doll");
                link_me = TRUE;
                rez_object("Object", <-0.1975, 0.6894, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
            } else {
                llSetLinkPrimitiveParamsFast(2, [
                    PRIM_NAME, "rotatebar"
                ]);

                log("Rezzing alpha doll");
                link_me = TRUE;
                rez_object("ruthdollv3", alpha_doll_pos, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
            }
        }
        else if (counter == 4) {
            log("Configuring alpha doll");
            if (ROTH) {
                llSetLinkPrimitiveParamsFast(2, [
                    PRIM_NAME, "alphadoll",
                    PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                    PRIM_TEXTURE, 4, alpha_doll_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                    PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                    PRIM_SIZE, <0.01, 0.3, 0.3>
                ]);
            } else {
                llSetLinkPrimitiveParamsFast(2, [
                    PRIM_NAME, "chest"
                ]);
            }

            log("Rezzing alpha button 0");
            link_me = TRUE;
            num_repeat = 0;
            rez_object("4x1_outline_button", llList2Vector(alpha_button_pos, 0), <PI, 0.0, 0.0>);
        }
        else if (counter == 5) {
            list hoffset = [alpha_button_left_offset, alpha_button_right_offset];
            // 0,1 = left; 2,3 = right
            integer hindex = (num_repeat & 2) >> 1;
            // even = 0, odd = 4
            integer vindex = (num_repeat & 1) << 2;

            log("Configuring alpha button " + (string)num_repeat);
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "alpha" + (string)num_repeat,
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 0, alpha_button_texture, alpha_button_scale, (vector)("<"+llList2String(hoffset, hindex)+","+llList2String(alpha_button_voffset, vindex)+",0.0>"), PI_BY_TWO,
                PRIM_TEXTURE, 2, alpha_button_texture, alpha_button_scale, (vector)("<"+llList2String(hoffset, hindex)+","+llList2String(alpha_button_voffset, vindex+1)+",0.0>"), PI_BY_TWO,
                PRIM_TEXTURE, 4, alpha_button_texture, alpha_button_scale, (vector)("<"+llList2String(hoffset, hindex)+","+llList2String(alpha_button_voffset, vindex+2)+",0.0>"), PI_BY_TWO,
                PRIM_TEXTURE, 6, alpha_button_texture, alpha_button_scale, (vector)("<"+llList2String(hoffset, hindex)+","+llList2String(alpha_button_voffset, vindex+3)+",0.0>"), PI_BY_TWO,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, <0.01, 0.125, 0.080>
            ]);
            if (num_repeat < 3) {
                // do another one
                num_repeat++;
                counter--;
                log("Rezzing alpha button " + (string)num_repeat);
                link_me = TRUE;
                rez_object("4x1_outline_button", llList2Vector(alpha_button_pos, num_repeat), <PI, 0.0, 0.0>);
            } else {
                // move on to next

        // ***** Skin HUD *****

                // Set counter for skin panel
                counter = 10;

                log("Rezzing skinbar (north)");
                link_me = TRUE;
                rez_object("Object", <0.0, 0.0, 0.5>, <PI, 0.0, 0.0>);
            }
        }
        else if (counter == 11) {
            configure_header("skinbar", 0.187);

            log("Rezzing skin HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.6894>, <PI, 0.0, 0.0>);
        }
        else if (counter == 12) {
            log("Configuring skin HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skinbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, skin_texture, <1.0, 0.8, 0.0>, <0.0, 0.1, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing skin button 0");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, -0.1000, 0.5715>, <PI, 0.0, 0.0>);
        }
        else if (counter == 13) {
            log("Configuring skin tone button 0");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "sk0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, skin_texture, <0.087, 0.087, 0.00>, <-0.375, -0.437, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

            log("Rezzing skin button 1");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, 0.1000, 0.5715>, <PI, 0.0, 0.0>);
        }
        else if (counter == 14) {
            log("Configuring skin tone button 1");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "sk1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

            log("Rezzing skin button 2");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, -0.1000, 0.6213>, <PI, 0.0, 0.0>);
        }
        else if (counter == 15) {
            log("Configuring skin tone button 2");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "sk2",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

            log("Rezzing skin button 3");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, 0.1000, 0.6213>, <PI, 0.0, 0.0>);
        }
        else if (counter == 16) {
            log("Configuring skin tone button 3");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "sk3",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

            log("Rezzing amode button");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, 0.0000, 0.6712>, <PI, 0.0, 0.0>);
        }
        else if (counter == 17) {
            log("Configuring alpha mode button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "amode0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, skin_texture, <0.255, 0.064, 0.00>, <0.0, -0.438, 0.0>, 0.0,
                PRIM_TEXTURE, 4, skin_texture, <0.255, 0.064, 0.00>, <0.3134, -0.438, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.500, 0.035>
            ]);

            log("Rezzing eye button 0");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, -0.1000, 0.7580>, <PI, 0.0, 0.0>);
        }
        else if (counter == 18) {
            log("Configuring eye button 0");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "eye0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, skin_texture, <0.087, 0.087, 0.00>, <-0.375, -0.437, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

            log("Rezzing eye button 1");
            link_me = TRUE;
            rez_object("4x1_outline_button", <-0.2085, 0.1000, 0.7580>, <PI, 0.0, 0.0>);
        }
        else if (counter == 19) {
            log("Configuring eye button 1");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "eye1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.200, 0.050>
            ]);

        // ***** Option HUD *****

            // Set counter for option panel
            counter = 20;

            log("Rezzing optionbar (east)");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.5, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 21) {
            configure_header("optionbar", 0.062);

            log("Rezzing option HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.6894, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 22) {
            log("Configuring option HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "optionbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_TEXTURE, 4, options_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing hand pose button 0");
            link_me = TRUE;
            num_repeat = 0;
            rez_object("4x1_outline_button", llList2Vector(hand_button_pos, 0), <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 23) {
            log("Configuring hand pose button " + (string)num_repeat);
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp" + (string)num_repeat,
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.10, 0.025>
            ]);

            if (num_repeat < 6) {
                // do another one
                num_repeat++;
                counter--;
                log("Rezzing hand pose button " + (string)num_repeat);
                link_me = TRUE;
                rez_object("4x1_outline_button", llList2Vector(hand_button_pos, num_repeat), <-PI_BY_TWO, 0.0, 0.0>);
            } else {
                // move on to next

                // Set counter for skin panel
                counter = 26;
                log("Rezzing fingernail color buttons");
                link_me = TRUE;
                rez_object("5x1-s_button", <-0.2025, -0.6037, -0.04297>, <-PI_BY_TWO, 0.0, 0.0>);
            }
        }
        else if (counter == 27) {
            configure_color_buttons("fnc0");

            log("Rezzing fingernail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6037, 0.10695>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 28) {
            configure_color_buttons("fnc1");

            log("Rezzing toenail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, -0.04297>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 29) {
            configure_color_buttons("tnc0");

            log("Rezzing toenail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, 0.10695>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 30) {
            configure_color_buttons("tnc1");

            if (ROTH)
                return;

        // Ruth only from here down
            log("Rezzing ankle lock button");
            link_me = TRUE;
            rez_object("Object", <-0.2025, -0.8130, -0.15891>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 31) {
            log("Configuring ankle lock button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fp0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, options_texture, <0.12, 0.12, 0.0>, <0.44, -0.44, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.05, 0.05>
            ]);

            log("Rezzing foot pose buttons");
            link_me = TRUE;
            rez_object("6x1_button", <-0.2025, -0.813, 0.0315>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 32) {
            log("Configuring foot pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fp1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.3, 0.05>
            ]);

            log("Rezzing fingernail shape buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.5693, 0.03198>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 33) {
            log("Configuring fingernail shape buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fns0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 0, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.375, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 1, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 3, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.375, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
//                PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
//                PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
                PRIM_COLOR, 4, <0.0, 0.0, 0.0>, 1.00,
                PRIM_SIZE, <0.01, 0.295, 0.035>
            ]);
        }
    }
}
