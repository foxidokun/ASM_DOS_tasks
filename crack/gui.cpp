#include <SFML/Graphics.hpp>
#include <time.h>
#include <string.h>
#include "common.h"
#include "gui.h"
#include "ascii_arts.h"

// ---------------------------------------------------------------------------------------------------------------------

const int SCREEN_WIDTH       = 1920;
const int SCREEN_HEIGHT      = 1080;
const int FRAME_DELAY        = 150;
const int PROGRESS_FONT_SIZE = 40;
const int STATUS_FONT_SIZE   = 40;
const int PROGRESS_BUF_SIZE  = 32;
const int STATUS_BUF_SIZE    = 64;

const char FONT_FILENAME[]   = "hack.ttf";

// ---------------------------------------------------------------------------------------------------------------------

struct scene_t {
    sf::RenderWindow window;

    sf::Font font;

    sf::Text art;
    sf::Text progress;
    sf::Text status;
};

// ---------------------------------------------------------------------------------------------------------------------

int setup_scene (scene_t *self);
void close_scene (scene_t *self);

void set_status (scene_t *self, int progress_percent);

static void set_fonts(scene_t *self);
static void msleep(int msec);

// ---------------------------------------------------------------------------------------------------------------------

int cat_render()
{
    scene_t scene;
    if (setup_scene(&scene) == ERROR) {
        return ERROR;
    }

    // Render scenes
    char progress_buf[PROGRESS_BUF_SIZE];

    for (int i = 0; i < FRAME_CNT; ++i)
    {
        int progress_percent = (i * 100) / FRAME_CNT;

        scene.art.setString(FRAMES[i]);
        sprintf (progress_buf, "PROGRESS: %d%%", progress_percent);
        scene.progress.setString(progress_buf);

        set_status(&scene, progress_percent);

        scene.window.draw(scene.progress);
        scene.window.draw(scene.art);
        scene.window.draw(scene.status);

        scene.window.display();
        msleep(FRAME_DELAY);
        scene.window.clear();
    }

    close_scene(&scene);
    return 0;
}

// ---------------------------------------------------------------------------------------------------------------------
int setup_scene (scene_t *self) {
    self->window.create(sf::VideoMode(SCREEN_WIDTH, SCREEN_HEIGHT), "Hacking...",
                        sf::Style::Fullscreen);

    if (!self->font.loadFromFile(FONT_FILENAME)) {
        fprintf (stderr, "Failed to load font %s\n", FONT_FILENAME);
        return ERROR;
    }

    set_fonts(self);
    return 0;
}

void close_scene(scene_t *self) {
    self->window.close();
}

// ---------------------------------------------------------------------------------------------------------------------

#define SET_STATUS_STRING(str, threshold) {         \
    strcpy(strbuf, str);                            \
    n = sizeof (str) - 1;                           \
    n_dots = (progress_percent - threshold) / 2;    \
}

void set_status (scene_t *self, int progress_percent) {
    char strbuf[STATUS_BUF_SIZE] = "";

    int n = 0;
    int n_dots = 0;

    if (progress_percent <= 10) {
        SET_STATUS_STRING("Loading file", 0);
    } else if (progress_percent <= 30) {
        SET_STATUS_STRING("Analyzing", 10);
    } else if (progress_percent <= 60) {
        SET_STATUS_STRING("Removing Denuvo", 30);
    } else if (progress_percent <= 80) {
        SET_STATUS_STRING("Upgrading textures", 60);
    } else {
        SET_STATUS_STRING("Writing back", 80);
    }

    for (int i = 0; i < n_dots; ++i) {
        strbuf[n]   = '.';
        n++;
    }
    strbuf[n] = '\0';

    self->status.setString(strbuf);
}

#undef SET_STATUS_STRING

// ---------------------------------------------------------------------------------------------------------------------

static void set_fonts(scene_t *self) {
    self->art.setFont(self->font);
    self->art.setCharacterSize(3);
    self->art.setFillColor(sf::Color::Green);

    self->progress.setFont(self->font);
    self->progress.setFillColor(sf::Color::White);
    self->progress.setCharacterSize(PROGRESS_FONT_SIZE);

    self->status.setFont(self->font);
    self->status.setFillColor(sf::Color::Cyan);
    self->status.setCharacterSize(STATUS_FONT_SIZE);
    self->status.setPosition(10, 1020);
}

// ---------------------------------------------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------------------------------------------

static void msleep(int msec) {
    struct timespec ts = {};
    int res;


    ts.tv_sec = msec / 1000;
    ts.tv_nsec = (msec % 1000) * 1000000;

    res = nanosleep(&ts, &ts);
}