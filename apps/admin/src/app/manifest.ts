import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/dashboard",
    name: "Dream Team Admin",
    short_name: "Dream Team",
    description: "WPCC attendance and membership administration dashboard.",
    start_url: "/dashboard",
    scope: "/",
    display: "standalone",
    background_color: "#0d0f0e",
    theme_color: "#123b2a",
    orientation: "any",
    lang: "en-NG",
    icons: [
      {
        src: "/wpcc-logo.png",
        sizes: "1024x1024",
        type: "image/png",
        purpose: "any",
      },
    ],
    shortcuts: [
      { name: "Members", short_name: "Members", url: "/dashboard/members" },
      { name: "Attendance", short_name: "Attendance", url: "/dashboard/events" },
      { name: "Departments", short_name: "Departments", url: "/dashboard/departments" },
    ],
  };
}
