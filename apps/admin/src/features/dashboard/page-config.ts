export type DashboardPageConfig = {
  title: string;
  description: string;
  action?: string;
  secondaryAction?: string;
  metrics: readonly string[];
  sectionTitle: string;
};

export const dashboardPages: Record<string, DashboardPageConfig> = {
  "": { title: "Overview", description: "Plan, care for and engage your church membership with clarity.", action: "Add member", metrics: ["Total members", "Active members", "Souls won", "New members"], sectionTitle: "Recent activity" },
  analytics: { title: "Analytics reports", description: "Compare church growth and ministry performance across selected periods.", action: "Export report", metrics: ["Total members", "Active-member rate", "Souls won", "Recorded attendance"], sectionTitle: "Performance indicators" },
  members: { title: "Members", description: "Manage member profiles, care status, departments and engagement records.", action: "Add member", secondaryAction: "Export members", metrics: ["Total members", "Active", "New this month", "Needs follow-up"], sectionTitle: "Membership directory" },
  events: { title: "Events", description: "Manage church events and review attendance performance.", metrics: ["Total events", "Total attendance", "Average attendance", "Latest event"], sectionTitle: "Event directory" },
  "soul-winning": { title: "Soul winning", description: "Track outreach events, new converts and their integration journey.", action: "Add campaign", metrics: ["Souls won", "Contacted", "Integrated", "Awaiting contact"], sectionTitle: "Soul-winning register" },
  departments: { title: "Departments", description: "Monitor ministry teams, leaders and member participation.", action: "Download report", metrics: ["Departments", "Assigned members", "Department leaders", "Average attendance"], sectionTitle: "Department directory" },
  enquiries: { title: "Enquiries", description: "Manage requests from members, guests and the public with clear ownership.", metrics: ["Open enquiries", "In review", "Resolved", "Overdue"], sectionTitle: "Enquiry inbox" },
  "quality-control/reports": { title: "QC reports inbox", description: "Review member and leader reports requiring quality-control attention.", metrics: ["Open reports", "Active queries", "Open issues", "Average resolution"], sectionTitle: "Reports inbox" },
  "quality-control/queries": { title: "Queries", description: "Assign formal quality-control queries and monitor responses and due dates.", action: "Assign query", metrics: ["Open queries", "Awaiting response", "Overdue", "Responded"], sectionTitle: "Assigned queries" },
  "quality-control/issues": { title: "Issue tracker", description: "Track operational issues from investigation through resolution.", metrics: ["Open issues", "Critical", "In progress", "Resolved"], sectionTitle: "Issue register" },
  "academy/classes": { title: "Classes", description: "Manage church academy classes, learning tracks, schedules and completion progress.", metrics: ["Active classes", "Enrolled learners", "Instructors", "Completion rate"], sectionTitle: "Class directory" },
  "academy/enrolments": { title: "Enrolments", description: "Track academy registrations, admission status, attendance and learning progress.", metrics: ["Total enrolments", "In progress", "Completed", "Awaiting placement"], sectionTitle: "Enrolment directory" },
  "academy/instructors": { title: "Instructors", description: "Manage academy facilitators, teaching assignments, learner loads and availability.", metrics: ["Instructors in session", "Active instructors", "Classes assigned", "Average completion"], sectionTitle: "Instructor directory" },
  "follow-ups": { title: "Follow-ups", description: "Coordinate care actions, outreach callbacks, member follow-through and email communication.", metrics: ["Campaigns sent", "Recipients reached", "Delivery rate", "Calls pending"], sectionTitle: "Campaign history" },
  targets: { title: "Targets", description: "Set measurable goals across membership, evangelism, attendance and app adoption.", action: "Create target", metrics: ["Active targets", "On track", "Completed", "At risk"], sectionTitle: "Target register" },
  awards: { title: "Awards", description: "Celebrate goals, milestones and accomplishments achieved across the church.", metrics: ["Awards earned", "This quarter", "Periods represented", "Latest award"], sectionTitle: "Award gallery" },
};

export function getDashboardPage(path: string): DashboardPageConfig | undefined {
  if (path.startsWith("departments/") && path !== "departments") {
    return { title: "Department details", description: "Review department membership, leadership and attendance performance.", metrics: ["Total members", "Active members", "Department leaders", "Attendance"], sectionTitle: "Department members" };
  }
  return dashboardPages[path];
}
