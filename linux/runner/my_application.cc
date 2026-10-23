#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// FLUTTER_PHONE_SIMULATOR_V1
// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Called periodically to update the phone status bar time
static gboolean update_time_cb(gpointer user_data) {
  GtkLabel* label = GTK_LABEL(user_data);
  GDateTime* now = g_date_time_new_now_local();
  gchar* time_str = g_date_time_format(now, "%H:%M");
  gtk_label_set_text(label, time_str);
  g_free(time_str);
  g_date_time_unref(now);
  return G_SOURCE_CONTINUE;
}

// Draws the Samsung Galaxy S25 FE punch-hole selfie camera
static gboolean draw_camera_cb(GtkWidget* widget, cairo_t* cr, gpointer data) {
  // Outer black lens cutout
  cairo_set_source_rgb(cr, 0.05, 0.05, 0.05);
  cairo_arc(cr, 6.0, 7.0, 5.0, 0, 2 * G_PI);
  cairo_fill(cr);

  // Subtle dark-blue glass reflection
  cairo_set_source_rgba(cr, 0.25, 0.45, 0.85, 0.7);
  cairo_arc(cr, 5.0, 6.0, 1.5, 0, 2 * G_PI);
  cairo_fill(cr);
  return FALSE;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Setup Samsung S25 FE Status Bar styling
  GtkCssProvider* provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(provider,
    "headerbar.phone-status-bar {"
    "  min-height: 28px;"
    "  padding: 0 10px;"
    "  background-color: #121212;"
    "  border: none;"
    "  box-shadow: none;"
    "}"
    "headerbar.phone-status-bar label {"
    "  color: #f1f1f1;"
    "  font-size: 11px;"
    "  font-weight: 600;"
    "  font-family: sans-serif;"
    "}"
    "headerbar.phone-status-bar image {"
    "  color: #f1f1f1;"
    "}"
    "headerbar.phone-status-bar button.close {"
    "  min-height: 16px;"
    "  min-width: 16px;"
    "  padding: 0;"
    "  margin: 0 0 0 6px;"
    "  background: transparent;"
    "  border: none;"
    "  box-shadow: none;"
    "  color: #888888;"
    "}"
    "headerbar.phone-status-bar button.close:hover {"
    "  color: #ff5555;"
    "}", -1, nullptr);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(),
      GTK_STYLE_PROVIDER(provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(provider);

  GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
  gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(header_bar)), "phone-status-bar");
  gtk_header_bar_set_show_close_button(header_bar, TRUE);

  // Left: Clock (HH:MM)
  GDateTime* now = g_date_time_new_now_local();
  gchar* time_str = g_date_time_format(now, "%H:%M");
  GtkWidget* time_label = gtk_label_new(time_str);
  g_free(time_str);
  g_date_time_unref(now);
  g_timeout_add_seconds(30, update_time_cb, time_label);
  gtk_header_bar_pack_start(header_bar, time_label);

  // Center: Samsung S25 FE Punch-Hole Camera
  GtkWidget* camera_dot = gtk_drawing_area_new();
  gtk_widget_set_size_request(camera_dot, 12, 14);
  g_signal_connect(G_OBJECT(camera_dot), "draw", G_CALLBACK(draw_camera_cb), NULL);
  gtk_header_bar_set_custom_title(header_bar, camera_dot);

  // Right: 5G, Wi-Fi, Battery
  GtkWidget* status_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 5);
  GtkWidget* network_label = gtk_label_new("5G");
  GtkWidget* wifi_icon = gtk_image_new_from_icon_name("network-wireless-symbolic", GTK_ICON_SIZE_MENU);
  GtkWidget* battery_icon = gtk_image_new_from_icon_name("battery-full-symbolic", GTK_ICON_SIZE_MENU);

  gtk_box_pack_start(GTK_BOX(status_box), network_label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(status_box), wifi_icon, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(status_box), battery_icon, FALSE, FALSE, 0);
  gtk_header_bar_pack_end(header_bar, status_box);

  gtk_widget_show_all(GTK_WIDGET(header_bar));
  gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  gtk_window_set_title(window, "Flutter Phone Simulator (Samsung Galaxy S25 FE)");

  // Samsung Galaxy S25 FE logical resolution (19.5:9 ratio)
  gint width = 412;
  gint height = 915;

  const char* env_orientation = g_getenv("ORIENTATION");
  if (env_orientation != nullptr && g_strcmp0(env_orientation, "landscape") == 0) {
    width = 915;
    height = 412;
  }

  if (self->dart_entrypoint_arguments != nullptr) {
    for (char** arg = self->dart_entrypoint_arguments; *arg != nullptr; ++arg) {
      if (g_strcmp0(*arg, "--landscape") == 0) {
        width = 915;
        height = 412;
      } else if (g_strcmp0(*arg, "--portrait") == 0) {
        width = 412;
        height = 915;
      }
    }
  }

  gtk_window_set_default_size(window, width, height);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
