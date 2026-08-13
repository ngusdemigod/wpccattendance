export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      academy_instructor_assignments: {
        Row: {
          branch_id: string
          course_id: string
          created_at: string
          created_by: string
          id: string
          instructor_id: string
          session_id: string | null
        }
        Insert: {
          branch_id: string
          course_id: string
          created_at?: string
          created_by: string
          id?: string
          instructor_id: string
          session_id?: string | null
        }
        Update: {
          branch_id?: string
          course_id?: string
          created_at?: string
          created_by?: string
          id?: string
          instructor_id?: string
          session_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "academy_instructor_assignments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_instructor_assignments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "academy_instructor_assignments_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_instructor_assignments_instructor_id_fkey"
            columns: ["instructor_id"]
            isOneToOne: false
            referencedRelation: "academy_instructors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_instructor_assignments_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "academy_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_instructors: {
        Row: {
          active: boolean
          bio: string | null
          branch_id: string
          created_at: string
          created_by: string
          id: string
          profile_id: string
        }
        Insert: {
          active?: boolean
          bio?: string | null
          branch_id: string
          created_at?: string
          created_by: string
          id?: string
          profile_id: string
        }
        Update: {
          active?: boolean
          bio?: string | null
          branch_id?: string
          created_at?: string
          created_by?: string
          id?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_instructors_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_instructors_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "academy_instructors_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "academy_instructors_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_instructors_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      academy_module_attachments: {
        Row: {
          branch_id: string
          bucket_name: string
          checksum_sha256: string | null
          created_at: string
          created_by: string
          file_name: string
          id: string
          mime_type: string
          module_id: string
          object_path: string
          size_bytes: number
        }
        Insert: {
          branch_id: string
          bucket_name?: string
          checksum_sha256?: string | null
          created_at?: string
          created_by: string
          file_name: string
          id?: string
          mime_type: string
          module_id: string
          object_path: string
          size_bytes: number
        }
        Update: {
          branch_id?: string
          bucket_name?: string
          checksum_sha256?: string | null
          created_at?: string
          created_by?: string
          file_name?: string
          id?: string
          mime_type?: string
          module_id?: string
          object_path?: string
          size_bytes?: number
        }
        Relationships: [
          {
            foreignKeyName: "academy_module_attachments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_module_attachments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "academy_module_attachments_module_id_fkey"
            columns: ["module_id"]
            isOneToOne: false
            referencedRelation: "academy_modules"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_modules: {
        Row: {
          branch_id: string
          course_id: string
          created_at: string
          created_by: string
          description: string | null
          id: string
          position: number
          title: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          course_id: string
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          position?: number
          title: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          course_id?: string
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          position?: number
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_modules_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_modules_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "academy_modules_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_sessions: {
        Row: {
          branch_id: string
          capacity: number | null
          course_id: string
          created_at: string
          created_by: string
          ends_at: string | null
          id: string
          location: string | null
          starts_at: string
          status: string
          title: string
        }
        Insert: {
          branch_id: string
          capacity?: number | null
          course_id: string
          created_at?: string
          created_by: string
          ends_at?: string | null
          id?: string
          location?: string | null
          starts_at: string
          status?: string
          title: string
        }
        Update: {
          branch_id?: string
          capacity?: number | null
          course_id?: string
          created_at?: string
          created_by?: string
          ends_at?: string | null
          id?: string
          location?: string | null
          starts_at?: string
          status?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_sessions_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_sessions_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "academy_sessions_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
        ]
      }
      announcement_acknowledgements: {
        Row: {
          announcement_id: string
          created_at: string
          id: string
          user_id: string
        }
        Insert: {
          announcement_id: string
          created_at?: string
          id?: string
          user_id: string
        }
        Update: {
          announcement_id?: string
          created_at?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "announcement_acknowledgements_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "announcements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_acknowledgements_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "my_announcements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_acknowledgements_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "announcement_acknowledgements_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_acknowledgements_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      announcement_comments: {
        Row: {
          announcement_id: string
          body: string
          created_at: string
          id: string
          is_deleted: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          announcement_id: string
          body: string
          created_at?: string
          id?: string
          is_deleted?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          announcement_id?: string
          body?: string
          created_at?: string
          id?: string
          is_deleted?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "announcement_comments_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "announcements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_comments_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "my_announcements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "announcement_comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      announcement_media: {
        Row: {
          announcement_id: string
          created_at: string
          id: string
          media_url: string
          sort_order: number
        }
        Insert: {
          announcement_id: string
          created_at?: string
          id?: string
          media_url: string
          sort_order?: number
        }
        Update: {
          announcement_id?: string
          created_at?: string
          id?: string
          media_url?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "announcement_media_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "announcements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcement_media_announcement_id_fkey"
            columns: ["announcement_id"]
            isOneToOne: false
            referencedRelation: "my_announcements"
            referencedColumns: ["id"]
          },
        ]
      }
      announcements: {
        Row: {
          allow_comments: boolean
          branch_id: string | null
          content: string
          created_at: string | null
          created_by: string | null
          department_id: string | null
          hasmedia: boolean | null
          id: string
          is_pinned: boolean
          mediaurl: string | null
          scope: string
          title: string
        }
        Insert: {
          allow_comments?: boolean
          branch_id?: string | null
          content: string
          created_at?: string | null
          created_by?: string | null
          department_id?: string | null
          hasmedia?: boolean | null
          id?: string
          is_pinned?: boolean
          mediaurl?: string | null
          scope: string
          title: string
        }
        Update: {
          allow_comments?: boolean
          branch_id?: string | null
          content?: string
          created_at?: string | null
          created_by?: string | null
          department_id?: string | null
          hasmedia?: boolean | null
          id?: string
          is_pinned?: boolean
          mediaurl?: string | null
          scope?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "announcements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "announcements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "announcements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      attendance: {
        Row: {
          branch_id: string | null
          clockout: string | null
          closedlat: number | null
          closedlong: number | null
          confirmedby: string | null
          confirmedby_name: string | null
          created_at: string | null
          department_id: string | null
          event_id: string | null
          fullname: string
          id: string
          latitude: number | null
          longitude: number | null
          status: string | null
          user_id: string | null
        }
        Insert: {
          branch_id?: string | null
          clockout?: string | null
          closedlat?: number | null
          closedlong?: number | null
          confirmedby?: string | null
          confirmedby_name?: string | null
          created_at?: string | null
          department_id?: string | null
          event_id?: string | null
          fullname: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          status?: string | null
          user_id?: string | null
        }
        Update: {
          branch_id?: string | null
          clockout?: string | null
          closedlat?: number | null
          closedlong?: number | null
          confirmedby?: string | null
          confirmedby_name?: string | null
          created_at?: string | null
          department_id?: string | null
          event_id?: string | null
          fullname?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          status?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      attendance_audit_logs: {
        Row: {
          action: string
          distance_m: number | null
          event_id: string
          id: string
          latitude: number | null
          longitude: number | null
          occurred_at: string
          raw_payload: Json | null
          request_ip: unknown
          user_agent: string | null
          user_full_name: string | null
          user_id: string
        }
        Insert: {
          action: string
          distance_m?: number | null
          event_id: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          occurred_at?: string
          raw_payload?: Json | null
          request_ip?: unknown
          user_agent?: string | null
          user_full_name?: string | null
          user_id: string
        }
        Update: {
          action?: string
          distance_m?: number | null
          event_id?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          occurred_at?: string
          raw_payload?: Json | null
          request_ip?: unknown
          user_agent?: string | null
          user_full_name?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "attendance_audit_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "attendance_audit_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_audit_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      branch_events: {
        Row: {
          branch_id: string
          closed_at: string | null
          closed_reason: string | null
          created_at: string
          created_by: string
          description: string | null
          event_end_at: string | null
          event_start_at: string
          featured_url: string | null
          id: string
          is_active: boolean
          latitude: number | null
          location: string | null
          longitude: number | null
          source_recurring_event_id: string | null
          source_recurring_scope: string | null
          title: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          event_end_at?: string | null
          event_start_at: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          event_end_at?: string | null
          event_start_at?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "branch_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branch_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      branch_recurring_events: {
        Row: {
          branch_id: string
          created_at: string
          created_by: string
          day_of_month: number | null
          day_of_week: number | null
          description: string | null
          end_time: string
          featured_url: string | null
          id: string
          is_active: boolean
          month: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at: string
          week_of_month: number | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          created_by: string
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_time: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at?: string
          week_of_month?: number | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          created_by?: string
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_time?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type?: string
          start_time?: string
          title?: string
          updated_at?: string
          week_of_month?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "branch_recurring_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branch_recurring_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      branches: {
        Row: {
          address: string
          contactnumber: string | null
          created_at: string | null
          id: string
          lastmember: number
          name: string
          prefix: string | null
          slug: string
        }
        Insert: {
          address: string
          contactnumber?: string | null
          created_at?: string | null
          id?: string
          lastmember?: number
          name: string
          prefix?: string | null
          slug: string
        }
        Update: {
          address?: string
          contactnumber?: string | null
          created_at?: string | null
          id?: string
          lastmember?: number
          name?: string
          prefix?: string | null
          slug?: string
        }
        Relationships: []
      }
      broadcast_campaigns: {
        Row: {
          audience_category: string
          body: string
          branch_id: string
          channel: string
          created_at: string
          created_by: string
          id: string
          name: string
          scheduled_at: string | null
          sent_at: string | null
          status: string
          subject: string | null
          template_id: string | null
          updated_at: string
        }
        Insert: {
          audience_category?: string
          body: string
          branch_id: string
          channel: string
          created_at?: string
          created_by: string
          id?: string
          name: string
          scheduled_at?: string | null
          sent_at?: string | null
          status?: string
          subject?: string | null
          template_id?: string | null
          updated_at?: string
        }
        Update: {
          audience_category?: string
          body?: string
          branch_id?: string
          channel?: string
          created_at?: string
          created_by?: string
          id?: string
          name?: string
          scheduled_at?: string | null
          sent_at?: string | null
          status?: string
          subject?: string | null
          template_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "broadcast_campaigns_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "broadcast_campaigns_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "broadcast_campaigns_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "communication_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      broadcast_delivery_events: {
        Row: {
          branch_id: string
          created_at: string
          event_type: string
          id: string
          metadata: Json
          occurred_at: string
          provider_event_id: string
          recipient_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          event_type: string
          id?: string
          metadata?: Json
          occurred_at: string
          provider_event_id: string
          recipient_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          event_type?: string
          id?: string
          metadata?: Json
          occurred_at?: string
          provider_event_id?: string
          recipient_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "broadcast_delivery_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "broadcast_delivery_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "broadcast_delivery_events_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "broadcast_recipients"
            referencedColumns: ["id"]
          },
        ]
      }
      broadcast_recipients: {
        Row: {
          branch_id: string
          campaign_id: string
          created_at: string
          destination: string
          id: string
          profile_id: string | null
          provider_message_id: string | null
          status: string
        }
        Insert: {
          branch_id: string
          campaign_id: string
          created_at?: string
          destination: string
          id?: string
          profile_id?: string | null
          provider_message_id?: string | null
          status?: string
        }
        Update: {
          branch_id?: string
          campaign_id?: string
          created_at?: string
          destination?: string
          id?: string
          profile_id?: string | null
          provider_message_id?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "broadcast_recipients_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "broadcast_recipients_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "broadcast_recipients_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "broadcast_campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "broadcast_recipients_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "broadcast_recipients_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "broadcast_recipients_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      churchmetric_audit_events: {
        Row: {
          action: string
          actor_id: string
          branch_id: string
          created_at: string
          entity_id: string
          entity_type: string
          id: string
          metadata: Json
        }
        Insert: {
          action: string
          actor_id: string
          branch_id: string
          created_at?: string
          entity_id: string
          entity_type: string
          id?: string
          metadata?: Json
        }
        Update: {
          action?: string
          actor_id?: string
          branch_id?: string
          created_at?: string
          entity_id?: string
          entity_type?: string
          id?: string
          metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "churchmetric_audit_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "churchmetric_audit_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      comments: {
        Row: {
          body: string
          "commentor name": string | null
          created_at: string
          created_by: string | null
          id: string
          is_deleted: boolean | null
          is_edited: boolean | null
          modified_at: string
          more: Json | null
          parent_comment_id: string | null
          post_id: string
        }
        Insert: {
          body: string
          "commentor name"?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_deleted?: boolean | null
          is_edited?: boolean | null
          modified_at?: string
          more?: Json | null
          parent_comment_id?: string | null
          post_id: string
        }
        Update: {
          body?: string
          "commentor name"?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_deleted?: boolean | null
          is_edited?: boolean | null
          modified_at?: string
          more?: Json | null
          parent_comment_id?: string | null
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "comments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "comments_parent_comment_id_fkey"
            columns: ["parent_comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts_with_comments"
            referencedColumns: ["id"]
          },
        ]
      }
      communication_templates: {
        Row: {
          active: boolean
          body: string
          branch_id: string
          channel: string
          created_at: string
          created_by: string
          id: string
          name: string
          subject: string | null
          updated_at: string
        }
        Insert: {
          active?: boolean
          body: string
          branch_id: string
          channel: string
          created_at?: string
          created_by: string
          id?: string
          name: string
          subject?: string | null
          updated_at?: string
        }
        Update: {
          active?: boolean
          body?: string
          branch_id?: string
          channel?: string
          created_at?: string
          created_by?: string
          id?: string
          name?: string
          subject?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "communication_templates_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "communication_templates_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      course_enrollments: {
        Row: {
          branch_id: string | null
          category: string | null
          certificate_available: boolean
          completed: boolean | null
          completed_at: string | null
          course_id: string | null
          created_at: string | null
          due_at: string | null
          icon_key: string | null
          id: string
          module_index: number | null
          module_total: number | null
          progress_percent: number
          publication_id: string | null
          remaining_lessons: number | null
          session_id: string | null
          status: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          branch_id?: string | null
          category?: string | null
          certificate_available?: boolean
          completed?: boolean | null
          completed_at?: string | null
          course_id?: string | null
          created_at?: string | null
          due_at?: string | null
          icon_key?: string | null
          id?: string
          module_index?: number | null
          module_total?: number | null
          progress_percent?: number
          publication_id?: string | null
          remaining_lessons?: number | null
          session_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          branch_id?: string | null
          category?: string | null
          certificate_available?: boolean
          completed?: boolean | null
          completed_at?: string | null
          course_id?: string | null
          created_at?: string | null
          due_at?: string | null
          icon_key?: string | null
          id?: string
          module_index?: number | null
          module_total?: number | null
          progress_percent?: number
          publication_id?: string | null
          remaining_lessons?: number | null
          session_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "course_enrollments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_enrollments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "course_enrollments_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_enrollments_publication_id_fkey"
            columns: ["publication_id"]
            isOneToOne: false
            referencedRelation: "course_publications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_enrollments_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "academy_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "course_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      course_publications: {
        Row: {
          assigned_by_user_id: string | null
          available_from: string | null
          branch_id: string | null
          course_id: string
          created_at: string
          department_id: string | null
          due_at: string | null
          id: string
          is_active: boolean
          is_required: boolean
          scope_type: string
          updated_at: string
        }
        Insert: {
          assigned_by_user_id?: string | null
          available_from?: string | null
          branch_id?: string | null
          course_id: string
          created_at?: string
          department_id?: string | null
          due_at?: string | null
          id?: string
          is_active?: boolean
          is_required?: boolean
          scope_type: string
          updated_at?: string
        }
        Update: {
          assigned_by_user_id?: string | null
          available_from?: string | null
          branch_id?: string | null
          course_id?: string
          created_at?: string
          department_id?: string | null
          due_at?: string | null
          id?: string
          is_active?: boolean
          is_required?: boolean
          scope_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "course_publications_assigned_by_user_id_fkey"
            columns: ["assigned_by_user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "course_publications_assigned_by_user_id_fkey"
            columns: ["assigned_by_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_publications_assigned_by_user_id_fkey"
            columns: ["assigned_by_user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "course_publications_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_publications_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "course_publications_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_publications_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "course_publications_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_publications_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      courses: {
        Row: {
          branch_id: string | null
          code: string | null
          created_at: string | null
          description: string | null
          id: string
          status: string
          title: string | null
        }
        Insert: {
          branch_id?: string | null
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          status?: string
          title?: string | null
        }
        Update: {
          branch_id?: string | null
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          status?: string
          title?: string | null
        }
        Relationships: []
      }
      department_attachments: {
        Row: {
          branch_id: string
          bucket_name: string
          checksum_sha256: string | null
          created_at: string
          created_by: string
          department_id: string
          file_name: string
          id: string
          mime_type: string
          object_path: string
          size_bytes: number
        }
        Insert: {
          branch_id: string
          bucket_name?: string
          checksum_sha256?: string | null
          created_at?: string
          created_by: string
          department_id: string
          file_name: string
          id?: string
          mime_type: string
          object_path: string
          size_bytes: number
        }
        Update: {
          branch_id?: string
          bucket_name?: string
          checksum_sha256?: string | null
          created_at?: string
          created_by?: string
          department_id?: string
          file_name?: string
          id?: string
          mime_type?: string
          object_path?: string
          size_bytes?: number
        }
        Relationships: [
          {
            foreignKeyName: "department_attachments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_attachments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "department_attachments_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "department_attachments_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_attachments_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      department_requests: {
        Row: {
          created_at: string | null
          department_id: string | null
          id: string
          status: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          department_id?: string | null
          id?: string
          status?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          department_id?: string | null
          id?: string
          status?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "department_requests_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "department_requests_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_requests_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "department_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "department_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      departmental_events: {
        Row: {
          branch_id: string
          closed_at: string | null
          closed_reason: string | null
          created_at: string
          created_by: string
          department_id: string
          description: string | null
          event_end_at: string | null
          event_start_at: string
          featured_url: string | null
          id: string
          is_active: boolean
          latitude: number | null
          location: string | null
          longitude: number | null
          source_recurring_event_id: string | null
          source_recurring_scope: string | null
          title: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by: string
          department_id: string
          description?: string | null
          event_end_at?: string | null
          event_start_at: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string
          department_id?: string
          description?: string | null
          event_end_at?: string | null
          event_start_at?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "departmental_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departmental_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "departmental_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "departmental_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departmental_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      departmental_recurring_events: {
        Row: {
          branch_id: string
          created_at: string
          created_by: string
          day_of_month: number | null
          day_of_week: number | null
          department_id: string
          description: string | null
          end_time: string
          featured_url: string | null
          id: string
          is_active: boolean
          month: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at: string
          week_of_month: number | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          created_by: string
          day_of_month?: number | null
          day_of_week?: number | null
          department_id: string
          description?: string | null
          end_time: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at?: string
          week_of_month?: number | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          created_by?: string
          day_of_month?: number | null
          day_of_week?: number | null
          department_id?: string
          description?: string | null
          end_time?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type?: string
          start_time?: string
          title?: string
          updated_at?: string
          week_of_month?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "departmental_recurring_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departmental_recurring_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "departmental_recurring_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "departmental_recurring_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departmental_recurring_events_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      departments: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          name: string
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      email_rate_limits: {
        Row: {
          attempt_count: number
          identifier: string
          scope: string
          updated_at: string
          window_started_at: string
        }
        Insert: {
          attempt_count?: number
          identifier: string
          scope: string
          updated_at?: string
          window_started_at?: string
        }
        Update: {
          attempt_count?: number
          identifier?: string
          scope?: string
          updated_at?: string
          window_started_at?: string
        }
        Relationships: []
      }
      enquiries: {
        Row: {
          assigned_to: string | null
          body: string
          branch_id: string
          category: string
          created_at: string
          created_by: string
          due_at: string | null
          id: string
          member_id: string | null
          priority: string
          resolved_at: string | null
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          body: string
          branch_id: string
          category: string
          created_at?: string
          created_by: string
          due_at?: string | null
          id?: string
          member_id?: string | null
          priority?: string
          resolved_at?: string | null
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          body?: string
          branch_id?: string
          category?: string
          created_at?: string
          created_by?: string
          due_at?: string | null
          id?: string
          member_id?: string | null
          priority?: string
          resolved_at?: string | null
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "enquiries_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enquiries_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "enquiries_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "enquiries_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enquiries_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      enquiry_messages: {
        Row: {
          body: string
          branch_id: string
          created_at: string
          delivery_status: string
          enquiry_id: string
          id: string
          is_internal: boolean
          sender_id: string
        }
        Insert: {
          body: string
          branch_id: string
          created_at?: string
          delivery_status?: string
          enquiry_id: string
          id?: string
          is_internal?: boolean
          sender_id: string
        }
        Update: {
          body?: string
          branch_id?: string
          created_at?: string
          delivery_status?: string
          enquiry_id?: string
          id?: string
          is_internal?: boolean
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "enquiry_messages_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enquiry_messages_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "enquiry_messages_enquiry_id_fkey"
            columns: ["enquiry_id"]
            isOneToOne: false
            referencedRelation: "enquiries"
            referencedColumns: ["id"]
          },
        ]
      }
      evangelism_events: {
        Row: {
          branch_id: string
          created_at: string
          created_by: string
          description: string | null
          ends_at: string | null
          id: string
          location: string | null
          starts_at: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          created_by: string
          description?: string | null
          ends_at?: string | null
          id?: string
          location?: string | null
          starts_at: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          created_by?: string
          description?: string | null
          ends_at?: string | null
          id?: string
          location?: string | null
          starts_at?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "evangelism_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "evangelism_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      events_legacy: {
        Row: {
          branch_id: string | null
          "closed by": string | null
          created_at: string | null
          created_by: string
          description: string | null
          endtime: string | null
          event_date: string | null
          featured_url: string | null
          id: string
          isactive: boolean
          latitude: number | null
          location: string | null
          longitude: number | null
          recurring_event_id: string | null
          scope: string
          title: string
        }
        Insert: {
          branch_id?: string | null
          "closed by"?: string | null
          created_at?: string | null
          created_by: string
          description?: string | null
          endtime?: string | null
          event_date?: string | null
          featured_url?: string | null
          id?: string
          isactive?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          recurring_event_id?: string | null
          scope: string
          title: string
        }
        Update: {
          branch_id?: string | null
          "closed by"?: string | null
          created_at?: string | null
          created_by?: string
          description?: string | null
          endtime?: string | null
          event_date?: string | null
          featured_url?: string | null
          id?: string
          isactive?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          recurring_event_id?: string | null
          scope?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "events_recurring_event_id_fkey"
            columns: ["recurring_event_id"]
            isOneToOne: false
            referencedRelation: "recurring_events_legacy"
            referencedColumns: ["id"]
          },
        ]
      }
      global_admins: {
        Row: {
          assigned_at: string
          created_at: string | null
          id: string
          is_active: boolean
          title_id: string | null
        }
        Insert: {
          assigned_at?: string
          created_at?: string | null
          id: string
          is_active?: boolean
          title_id?: string | null
        }
        Update: {
          assigned_at?: string
          created_at?: string | null
          id?: string
          is_active?: boolean
          title_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "global_admins_title_id_fkey"
            columns: ["title_id"]
            isOneToOne: false
            referencedRelation: "leadership_titles"
            referencedColumns: ["id"]
          },
        ]
      }
      global_events: {
        Row: {
          closed_at: string | null
          closed_reason: string | null
          created_at: string
          created_by: string
          description: string | null
          event_end_at: string | null
          event_start_at: string
          featured_url: string | null
          id: string
          is_active: boolean
          latitude: number | null
          location: string | null
          longitude: number | null
          source_recurring_event_id: string | null
          source_recurring_scope: string | null
          title: string
          updated_at: string
        }
        Insert: {
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          event_end_at?: string | null
          event_start_at: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          closed_at?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          event_end_at?: string | null
          event_start_at?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          source_recurring_event_id?: string | null
          source_recurring_scope?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      global_recurring_events: {
        Row: {
          created_at: string
          created_by: string
          day_of_month: number | null
          day_of_week: number | null
          description: string | null
          end_time: string
          featured_url: string | null
          id: string
          is_active: boolean
          month: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at: string
          week_of_month: number | null
        }
        Insert: {
          created_at?: string
          created_by: string
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_time: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type: string
          start_time: string
          title: string
          updated_at?: string
          week_of_month?: number | null
        }
        Update: {
          created_at?: string
          created_by?: string
          day_of_month?: number | null
          day_of_week?: number | null
          description?: string | null
          end_time?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean
          month?: number | null
          recurrence_type?: string
          start_time?: string
          title?: string
          updated_at?: string
          week_of_month?: number | null
        }
        Relationships: []
      }
      leaders: {
        Row: {
          branch_id: string
          created_at: string | null
          department_id: string
          end_date: string | null
          id: string
          is_active: boolean
          start_date: string | null
          title_id: string
          user_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string | null
          department_id: string
          end_date?: string | null
          id?: string
          is_active?: boolean
          start_date?: string | null
          title_id: string
          user_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string | null
          department_id?: string
          end_date?: string | null
          id?: string
          is_active?: boolean
          start_date?: string | null
          title_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "leaders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "leaders_title_id_fkey"
            columns: ["title_id"]
            isOneToOne: false
            referencedRelation: "leadership_titles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      leadership_titles: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          name: string
          parent_role_id: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          parent_role_id: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          parent_role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "leadership_titles_parent_role_id_fkey"
            columns: ["parent_role_id"]
            isOneToOne: false
            referencedRelation: "department_leadership_view"
            referencedColumns: ["parent_role_id"]
          },
          {
            foreignKeyName: "leadership_titles_parent_role_id_fkey"
            columns: ["parent_role_id"]
            isOneToOne: false
            referencedRelation: "roletypes"
            referencedColumns: ["id"]
          },
        ]
      }
      membership_code_sequences: {
        Row: {
          code_width: number
          last_value: number
          sequence_name: string
          updated_at: string
        }
        Insert: {
          code_width?: number
          last_value?: number
          sequence_name: string
          updated_at?: string
        }
        Update: {
          code_width?: number
          last_value?: number
          sequence_name?: string
          updated_at?: string
        }
        Relationships: []
      }
      membershipcode: {
        Row: {
          memberid: string
          membershipcode: string
        }
        Insert: {
          memberid: string
          membershipcode: string
        }
        Update: {
          memberid?: string
          membershipcode?: string
        }
        Relationships: [
          {
            foreignKeyName: "membershipcode_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: true
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "membershipcode_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "membershipcode_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: true
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      notification_outbox: {
        Row: {
          aggregate_id: string
          attempts: number
          available_at: string
          branch_id: string
          channel: string
          created_at: string
          event_type: string
          id: string
          idempotency_key: string
          last_error: string | null
          locked_at: string | null
          payload: Json
          processed_at: string | null
          status: string
        }
        Insert: {
          aggregate_id: string
          attempts?: number
          available_at?: string
          branch_id: string
          channel: string
          created_at?: string
          event_type: string
          id?: string
          idempotency_key: string
          last_error?: string | null
          locked_at?: string | null
          payload: Json
          processed_at?: string | null
          status?: string
        }
        Update: {
          aggregate_id?: string
          attempts?: number
          available_at?: string
          branch_id?: string
          channel?: string
          created_at?: string
          event_type?: string
          id?: string
          idempotency_key?: string
          last_error?: string | null
          locked_at?: string | null
          payload?: Json
          processed_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_outbox_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_outbox_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      otp_cooldowns: {
        Row: {
          last_sent_at: string
          membership_code: string
        }
        Insert: {
          last_sent_at?: string
          membership_code: string
        }
        Update: {
          last_sent_at?: string
          membership_code?: string
        }
        Relationships: []
      }
      penalties: {
        Row: {
          active: boolean | null
          created_at: string | null
          id: string
          punishment: string | null
          reason: string | null
          reported_by: string | null
          user_id: string | null
        }
        Insert: {
          active?: boolean | null
          created_at?: string | null
          id?: string
          punishment?: string | null
          reason?: string | null
          reported_by?: string | null
          user_id?: string | null
        }
        Update: {
          active?: boolean | null
          created_at?: string | null
          id?: string
          punishment?: string | null
          reason?: string | null
          reported_by?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "penalties_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "penalties_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "penalties_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "penalties_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "penalties_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "penalties_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      post_reactions: {
        Row: {
          created_at: string
          id: string
          post_id: string
          reaction_type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          reaction_type: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          reaction_type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_reactions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_reactions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts_with_comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "post_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      posts: {
        Row: {
          body: string | null
          branch_id: string | null
          comments_count: number | null
          created_at: string
          created_by: string | null
          department_id: string | null
          id: string
          is_archived: boolean | null
          is_pinned: boolean | null
          modified_at: string
          modified_by: string | null
          more: Json | null
          reaction_counts: Json
          target_type: string
          title: string
        }
        Insert: {
          body?: string | null
          branch_id?: string | null
          comments_count?: number | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          id?: string
          is_archived?: boolean | null
          is_pinned?: boolean | null
          modified_at?: string
          modified_by?: string | null
          more?: Json | null
          reaction_counts?: Json
          target_type?: string
          title: string
        }
        Update: {
          body?: string | null
          branch_id?: string | null
          comments_count?: number | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          id?: string
          is_archived?: boolean | null
          is_pinned?: boolean | null
          modified_at?: string
          modified_by?: string | null
          more?: Json | null
          reaction_counts?: Json
          target_type?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      profile_key_recipients: {
        Row: {
          created_at: string
          id: string
          key_version: number
          profile_user_id: string
          recipient_user_id: string
          wrap_algorithm: string
          wrap_nonce: string | null
          wrapped_dek: string
        }
        Insert: {
          created_at?: string
          id?: string
          key_version?: number
          profile_user_id: string
          recipient_user_id: string
          wrap_algorithm: string
          wrap_nonce?: string | null
          wrapped_dek: string
        }
        Update: {
          created_at?: string
          id?: string
          key_version?: number
          profile_user_id?: string
          recipient_user_id?: string
          wrap_algorithm?: string
          wrap_nonce?: string | null
          wrapped_dek?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar: string | null
          avatar_encryption_algorithm: string
          avatar_encryption_version: number
          avatar_is_encrypted: boolean
          avatar_nonce: string | null
          avatar_storage_path: string | null
          bio: string | null
          branch_id: string
          created_at: string | null
          date_joined: string | null
          department_id: string | null
          display_name: string | null
          email: string | null
          firstname: string | null
          full_name: string
          id: string
          initials: string | null
          lastname: string | null
          membership_code: string | null
          phone: string | null
          prefix: string | null
          setup_completed: boolean
          setup_completed_at: string | null
          updated_at: string
          verified: boolean | null
        }
        Insert: {
          avatar?: string | null
          avatar_encryption_algorithm?: string
          avatar_encryption_version?: number
          avatar_is_encrypted?: boolean
          avatar_nonce?: string | null
          avatar_storage_path?: string | null
          bio?: string | null
          branch_id: string
          created_at?: string | null
          date_joined?: string | null
          department_id?: string | null
          display_name?: string | null
          email?: string | null
          firstname?: string | null
          full_name: string
          id?: string
          initials?: string | null
          lastname?: string | null
          membership_code?: string | null
          phone?: string | null
          prefix?: string | null
          setup_completed?: boolean
          setup_completed_at?: string | null
          updated_at?: string
          verified?: boolean | null
        }
        Update: {
          avatar?: string | null
          avatar_encryption_algorithm?: string
          avatar_encryption_version?: number
          avatar_is_encrypted?: boolean
          avatar_nonce?: string | null
          avatar_storage_path?: string | null
          bio?: string | null
          branch_id?: string
          created_at?: string | null
          date_joined?: string | null
          department_id?: string | null
          display_name?: string | null
          email?: string | null
          firstname?: string | null
          full_name?: string
          id?: string
          initials?: string | null
          lastname?: string | null
          membership_code?: string | null
          phone?: string | null
          prefix?: string | null
          setup_completed?: boolean
          setup_completed_at?: string | null
          updated_at?: string
          verified?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      profiles_priv_info: {
        Row: {
          address: string | null
          avatar: string | null
          bio: string | null
          branch_id: string
          created_at: string | null
          date_joined: string | null
          date_joined_wpcc: string | null
          date_of_birth: string | null
          department_id: string | null
          dob: string | null
          email: string | null
          emergency_contact: string | null
          firstname: string | null
          full_name: string
          gender: string | null
          id: string
          lastname: string | null
          marital_status: string | null
          maturity_class_completed: string | null
          membership_code: string | null
          ministry_class_completed: string | null
          mission_class_completed: string | null
          occupation: string | null
          phone: string | null
          phone_number: string | null
          prefix: string | null
          profilecomplete: boolean
          residential_address: string | null
          role: string | null
          verified: boolean | null
          water_baptism_date: string | null
        }
        Insert: {
          address?: string | null
          avatar?: string | null
          bio?: string | null
          branch_id: string
          created_at?: string | null
          date_joined?: string | null
          date_joined_wpcc?: string | null
          date_of_birth?: string | null
          department_id?: string | null
          dob?: string | null
          email?: string | null
          emergency_contact?: string | null
          firstname?: string | null
          full_name: string
          gender?: string | null
          id?: string
          lastname?: string | null
          marital_status?: string | null
          maturity_class_completed?: string | null
          membership_code?: string | null
          ministry_class_completed?: string | null
          mission_class_completed?: string | null
          occupation?: string | null
          phone?: string | null
          phone_number?: string | null
          prefix?: string | null
          profilecomplete?: boolean
          residential_address?: string | null
          role?: string | null
          verified?: boolean | null
          water_baptism_date?: string | null
        }
        Update: {
          address?: string | null
          avatar?: string | null
          bio?: string | null
          branch_id?: string
          created_at?: string | null
          date_joined?: string | null
          date_joined_wpcc?: string | null
          date_of_birth?: string | null
          department_id?: string | null
          dob?: string | null
          email?: string | null
          emergency_contact?: string | null
          firstname?: string | null
          full_name?: string
          gender?: string | null
          id?: string
          lastname?: string | null
          marital_status?: string | null
          maturity_class_completed?: string | null
          membership_code?: string | null
          ministry_class_completed?: string | null
          mission_class_completed?: string | null
          occupation?: string | null
          phone?: string | null
          phone_number?: string | null
          prefix?: string | null
          profilecomplete?: boolean
          residential_address?: string | null
          role?: string | null
          verified?: boolean | null
          water_baptism_date?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_priv_info_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_priv_info_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "profiles_priv_info_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "profiles_priv_info_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_priv_info_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      profileverification: {
        Row: {
          id: string
          memberid: string
          status: boolean | null
          verifiedby: string | null
        }
        Insert: {
          id?: string
          memberid: string
          status?: boolean | null
          verifiedby?: string | null
        }
        Update: {
          id?: string
          memberid?: string
          status?: boolean | null
          verifiedby?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profileverification_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "profileverification_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profileverification_memberid_fkey"
            columns: ["memberid"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      provider_webhook_events: {
        Row: {
          id: string
          payload: Json
          processed_at: string | null
          processing_error: string | null
          provider: string
          provider_event_id: string
          received_at: string
        }
        Insert: {
          id?: string
          payload: Json
          processed_at?: string | null
          processing_error?: string | null
          provider: string
          provider_event_id: string
          received_at?: string
        }
        Update: {
          id?: string
          payload?: Json
          processed_at?: string | null
          processing_error?: string | null
          provider?: string
          provider_event_id?: string
          received_at?: string
        }
        Relationships: []
      }
      quality_issues: {
        Row: {
          area: string
          branch_id: string
          created_at: string
          created_by: string
          description: string
          id: string
          owner_id: string | null
          priority: string
          report_id: string | null
          resolved_at: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          area: string
          branch_id: string
          created_at?: string
          created_by: string
          description: string
          id?: string
          owner_id?: string | null
          priority?: string
          report_id?: string | null
          resolved_at?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          area?: string
          branch_id?: string
          created_at?: string
          created_by?: string
          description?: string
          id?: string
          owner_id?: string | null
          priority?: string
          report_id?: string | null
          resolved_at?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_issues_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_issues_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "quality_issues_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "quality_reports"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_queries: {
        Row: {
          body: string
          branch_id: string
          category: string
          created_at: string
          created_by: string
          due_at: string | null
          id: string
          issued_at: string
          priority: string
          report_id: string | null
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          body: string
          branch_id: string
          category?: string
          created_at?: string
          created_by: string
          due_at?: string | null
          id?: string
          issued_at?: string
          priority?: string
          report_id?: string | null
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          body?: string
          branch_id?: string
          category?: string
          created_at?: string
          created_by?: string
          due_at?: string | null
          id?: string
          issued_at?: string
          priority?: string
          report_id?: string | null
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_queries_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_queries_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "quality_queries_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "quality_reports"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_query_assignees: {
        Row: {
          assignee_id: string
          branch_id: string
          created_at: string
          id: string
          query_id: string
          responded_at: string | null
          response: string | null
        }
        Insert: {
          assignee_id: string
          branch_id: string
          created_at?: string
          id?: string
          query_id: string
          responded_at?: string | null
          response?: string | null
        }
        Update: {
          assignee_id?: string
          branch_id?: string
          created_at?: string
          id?: string
          query_id?: string
          responded_at?: string | null
          response?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_query_assignees_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_query_assignees_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "quality_query_assignees_query_id_fkey"
            columns: ["query_id"]
            isOneToOne: false
            referencedRelation: "quality_queries"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_reports: {
        Row: {
          assigned_to: string | null
          branch_id: string
          category: string
          created_at: string
          created_by: string
          description: string
          id: string
          priority: string
          reporter_id: string | null
          resolved_at: string | null
          source: string
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          branch_id: string
          category: string
          created_at?: string
          created_by: string
          description: string
          id?: string
          priority?: string
          reporter_id?: string | null
          resolved_at?: string | null
          source: string
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          branch_id?: string
          category?: string
          created_at?: string
          created_by?: string
          description?: string
          id?: string
          priority?: string
          reporter_id?: string | null
          resolved_at?: string | null
          source?: string
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_reports_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_reports_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "quality_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      quality_status_history: {
        Row: {
          branch_id: string
          changed_by: string
          created_at: string
          entity_id: string
          entity_type: string
          from_status: string | null
          id: string
          to_status: string
        }
        Insert: {
          branch_id: string
          changed_by: string
          created_at?: string
          entity_id: string
          entity_type: string
          from_status?: string | null
          id?: string
          to_status: string
        }
        Update: {
          branch_id?: string
          changed_by?: string
          created_at?: string
          entity_id?: string
          entity_type?: string
          from_status?: string | null
          id?: string
          to_status?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_status_history_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_status_history_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      recurring_events_legacy: {
        Row: {
          created_at: string | null
          day_of_month: number | null
          day_of_week: number
          description: string | null
          end_time: string
          featured_url: string | null
          id: string
          is_active: boolean | null
          month: number | null
          recurrence_type: string
          start_time: string
          title: string
          week_of_month: number | null
        }
        Insert: {
          created_at?: string | null
          day_of_month?: number | null
          day_of_week: number
          description?: string | null
          end_time: string
          featured_url?: string | null
          id?: string
          is_active?: boolean | null
          month?: number | null
          recurrence_type?: string
          start_time: string
          title: string
          week_of_month?: number | null
        }
        Update: {
          created_at?: string | null
          day_of_month?: number | null
          day_of_week?: number
          description?: string | null
          end_time?: string
          featured_url?: string | null
          id?: string
          is_active?: boolean | null
          month?: number | null
          recurrence_type?: string
          start_time?: string
          title?: string
          week_of_month?: number | null
        }
        Relationships: []
      }
      roles: {
        Row: {
          assigned_at: string
          branch_id: string | null
          department_id: string | null
          full_name: string
          id: string
          is_active: boolean
          is_primary: boolean
          leadership_title_id: string | null
          memberid: string
          roleid: string
          rolename: string | null
          scope_type: string
        }
        Insert: {
          assigned_at?: string
          branch_id?: string | null
          department_id?: string | null
          full_name: string
          id?: string
          is_active?: boolean
          is_primary?: boolean
          leadership_title_id?: string | null
          memberid: string
          roleid: string
          rolename?: string | null
          scope_type?: string
        }
        Update: {
          assigned_at?: string
          branch_id?: string | null
          department_id?: string | null
          full_name?: string
          id?: string
          is_active?: boolean
          is_primary?: boolean
          leadership_title_id?: string | null
          memberid?: string
          roleid?: string
          rolename?: string | null
          scope_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "roles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "roles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "roles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "roles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "roles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "roles_leadership_title_id_fkey"
            columns: ["leadership_title_id"]
            isOneToOne: false
            referencedRelation: "leadership_titles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "roles_roleid_fkey"
            columns: ["roleid"]
            isOneToOne: false
            referencedRelation: "department_leadership_view"
            referencedColumns: ["parent_role_id"]
          },
          {
            foreignKeyName: "roles_roleid_fkey"
            columns: ["roleid"]
            isOneToOne: false
            referencedRelation: "roletypes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "roles_rolename_fkey"
            columns: ["rolename"]
            isOneToOne: false
            referencedRelation: "department_leadership_view"
            referencedColumns: ["parent_role_name"]
          },
          {
            foreignKeyName: "roles_rolename_fkey"
            columns: ["rolename"]
            isOneToOne: false
            referencedRelation: "roletypes"
            referencedColumns: ["rolename"]
          },
        ]
      }
      roletypes: {
        Row: {
          description: string | null
          id: string
          rolename: string
        }
        Insert: {
          description?: string | null
          id?: string
          rolename: string
        }
        Update: {
          description?: string | null
          id?: string
          rolename?: string
        }
        Relationships: []
      }
      soul_followups: {
        Row: {
          assigned_to: string | null
          branch_id: string
          channel: string | null
          completed_at: string | null
          completed_by: string | null
          created_at: string
          created_by: string
          due_at: string | null
          id: string
          notes: string | null
          soul_id: string
          status: string
        }
        Insert: {
          assigned_to?: string | null
          branch_id: string
          channel?: string | null
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string
          created_by: string
          due_at?: string | null
          id?: string
          notes?: string | null
          soul_id: string
          status?: string
        }
        Update: {
          assigned_to?: string | null
          branch_id?: string
          channel?: string | null
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string
          created_by?: string
          due_at?: string | null
          id?: string
          notes?: string | null
          soul_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "soul_followups_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "soul_followups_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "soul_followups_soul_id_fkey"
            columns: ["soul_id"]
            isOneToOne: false
            referencedRelation: "souls"
            referencedColumns: ["id"]
          },
        ]
      }
      souls: {
        Row: {
          branch_id: string
          created_at: string
          email: string | null
          evangelism_event_id: string
          evangelist_name: string | null
          full_name: string
          id: string
          location: string | null
          phone: string | null
          phone_normalized: string | null
          recorded_by: string
          status: string
          updated_at: string
          won_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          email?: string | null
          evangelism_event_id: string
          evangelist_name?: string | null
          full_name: string
          id?: string
          location?: string | null
          phone?: string | null
          phone_normalized?: string | null
          recorded_by: string
          status?: string
          updated_at?: string
          won_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          email?: string | null
          evangelism_event_id?: string
          evangelist_name?: string | null
          full_name?: string
          id?: string
          location?: string | null
          phone?: string | null
          phone_normalized?: string | null
          recorded_by?: string
          status?: string
          updated_at?: string
          won_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "souls_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "souls_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "souls_evangelism_event_id_fkey"
            columns: ["evangelism_event_id"]
            isOneToOne: false
            referencedRelation: "evangelism_events"
            referencedColumns: ["id"]
          },
        ]
      }
      target_achievements: {
        Row: {
          achieved_at: string
          branch_id: string
          created_at: string
          id: string
          target_id: string
          title: string
        }
        Insert: {
          achieved_at?: string
          branch_id: string
          created_at?: string
          id?: string
          target_id: string
          title: string
        }
        Update: {
          achieved_at?: string
          branch_id?: string
          created_at?: string
          id?: string
          target_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "target_achievements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "target_achievements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "target_achievements_target_id_fkey"
            columns: ["target_id"]
            isOneToOne: true
            referencedRelation: "targets"
            referencedColumns: ["id"]
          },
        ]
      }
      target_progress_events: {
        Row: {
          branch_id: string
          created_at: string
          delta: number
          id: string
          idempotency_key: string
          recorded_by: string
          source_id: string | null
          source_type: string
          target_id: string
          value_after: number
        }
        Insert: {
          branch_id: string
          created_at?: string
          delta: number
          id?: string
          idempotency_key: string
          recorded_by: string
          source_id?: string | null
          source_type: string
          target_id: string
          value_after: number
        }
        Update: {
          branch_id?: string
          created_at?: string
          delta?: number
          id?: string
          idempotency_key?: string
          recorded_by?: string
          source_id?: string | null
          source_type?: string
          target_id?: string
          value_after?: number
        }
        Relationships: [
          {
            foreignKeyName: "target_progress_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "target_progress_events_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "target_progress_events_target_id_fkey"
            columns: ["target_id"]
            isOneToOne: false
            referencedRelation: "targets"
            referencedColumns: ["id"]
          },
        ]
      }
      targets: {
        Row: {
          branch_id: string
          created_at: string
          created_by: string
          current_value: number
          ends_at: string
          goal_value: number
          id: string
          metric: string
          notification_channels: string[]
          period_label: string | null
          period_type: string
          progress_step: number
          starts_at: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          created_by: string
          current_value?: number
          ends_at: string
          goal_value: number
          id?: string
          metric: string
          notification_channels?: string[]
          period_label?: string | null
          period_type: string
          progress_step?: number
          starts_at: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          created_by?: string
          current_value?: number
          ends_at?: string
          goal_value?: number
          id?: string
          metric?: string
          notification_channels?: string[]
          period_label?: string | null
          period_type?: string
          progress_step?: number
          starts_at?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "targets_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "targets_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      worker_private_profiles: {
        Row: {
          aad_context: Json
          address_ciphertext: string | null
          address_nonce: string | null
          created_at: string
          encryption_algorithm: string
          encryption_version: number
          id: string
          phone_ciphertext: string | null
          phone_nonce: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          aad_context?: Json
          address_ciphertext?: string | null
          address_nonce?: string | null
          created_at?: string
          encryption_algorithm?: string
          encryption_version?: number
          id?: string
          phone_ciphertext?: string | null
          phone_nonce?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          aad_context?: Json
          address_ciphertext?: string | null
          address_nonce?: string | null
          created_at?: string
          encryption_algorithm?: string
          encryption_version?: number
          id?: string
          phone_ciphertext?: string | null
          phone_nonce?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      worker_queries: {
        Row: {
          acknowledged_at: string | null
          attachment_url: string | null
          closed_at: string | null
          details: string
          escalates_at: string | null
          id: string
          opened_at: string
          raised_by_department: string | null
          raised_by_name: string | null
          raised_by_user_id: string | null
          requires_acknowledgement: boolean
          requires_response: boolean
          responded_at: string | null
          response_text: string | null
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          acknowledged_at?: string | null
          attachment_url?: string | null
          closed_at?: string | null
          details: string
          escalates_at?: string | null
          id?: string
          opened_at?: string
          raised_by_department?: string | null
          raised_by_name?: string | null
          raised_by_user_id?: string | null
          requires_acknowledgement?: boolean
          requires_response?: boolean
          responded_at?: string | null
          response_text?: string | null
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          acknowledged_at?: string | null
          attachment_url?: string | null
          closed_at?: string | null
          details?: string
          escalates_at?: string | null
          id?: string
          opened_at?: string
          raised_by_department?: string | null
          raised_by_name?: string | null
          raised_by_user_id?: string | null
          requires_acknowledgement?: boolean
          requires_response?: boolean
          responded_at?: string | null
          response_text?: string | null
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "worker_queries_raised_by_user_id_fkey"
            columns: ["raised_by_user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "worker_queries_raised_by_user_id_fkey"
            columns: ["raised_by_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "worker_queries_raised_by_user_id_fkey"
            columns: ["raised_by_user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "worker_queries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "worker_queries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "worker_queries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      workers: {
        Row: {
          branch_id: string
          created_at: string | null
          department_id: string | null
          id: string
          membershipcode: string
          user_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string | null
          department_id?: string | null
          id?: string
          membershipcode?: string
          user_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string | null
          department_id?: string | null
          id?: string
          membershipcode?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "workers_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
    }
    Views: {
      attendance_view: {
        Row: {
          attendance_created_at: string | null
          attendance_fullname: string | null
          attendance_id: string | null
          attendance_status: string | null
          branch_id: string | null
          branch_name: string | null
          clockout: string | null
          closedlat: number | null
          closedlong: number | null
          confirmedby: string | null
          confirmedby_name: string | null
          department_id: string | null
          department_name: string | null
          event_date: string | null
          event_id: string | null
          event_scope: string | null
          event_title: string | null
          latitude: number | null
          longitude: number | null
          profile_full_name: string | null
          profile_membership_code: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      department_leadership_view: {
        Row: {
          branch_id: string | null
          created_at: string | null
          department_id: string | null
          department_name: string | null
          end_date: string | null
          is_active: boolean | null
          leader_id: string | null
          parent_role_id: string | null
          parent_role_name: string | null
          start_date: string | null
          title_code: string | null
          title_description: string | null
          title_id: string | null
          title_name: string | null
          user_email: string | null
          user_full_name: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "leaders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "leaders_title_id_fkey"
            columns: ["title_id"]
            isOneToOne: false
            referencedRelation: "leadership_titles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      department_summary_view: {
        Row: {
          active_departmental_events: number | null
          department_id: string | null
          department_name: string | null
          past_departmental_events: number | null
          persons_count: number | null
        }
        Relationships: []
      }
      events: {
        Row: {
          branch_id: string | null
          "closed by": string | null
          created_at: string | null
          created_by: string | null
          description: string | null
          endtime: string | null
          event_date: string | null
          featured_url: string | null
          id: string | null
          isactive: boolean | null
          latitude: number | null
          location: string | null
          longitude: number | null
          recurring_event_id: string | null
          scope: string | null
          title: string | null
        }
        Relationships: []
      }
      events_attendance_view: {
        Row: {
          active_worker: number | null
          closed_by: string | null
          created_by: string | null
          created_time: string | null
          description: string | null
          event_branch_id: string | null
          event_end_time: string | null
          event_id: string | null
          event_scope: string | null
          event_start_date: string | null
          featured_image: string | null
          is_active: boolean | null
          latitude: number | null
          longitude: number | null
          title: string | null
          total_workers: number | null
        }
        Relationships: []
      }
      my_announcements: {
        Row: {
          acknowledged_by_current_user: boolean | null
          acknowledgement_count: number | null
          acknowledgement_preview_users: Json | null
          allow_comments: boolean | null
          branch_id: string | null
          branch_name: string | null
          comment_count: number | null
          content: string | null
          created_at: string | null
          creator_full_name: string | null
          department_id: string | null
          department_name: string | null
          hasmedia: boolean | null
          id: string | null
          images: Json | null
          is_pinned: boolean | null
          mediaurl: string | null
          scope: string | null
          scope_priority: number | null
          title: string | null
        }
        Relationships: [
          {
            foreignKeyName: "announcements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcements_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "announcements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      my_classes: {
        Row: {
          assigned_at: string | null
          available_from: string | null
          branch_id: string | null
          category: string | null
          certificate_available: boolean | null
          course_id: string | null
          department_id: string | null
          description: string | null
          due_at: string | null
          icon_key: string | null
          module_index: number | null
          module_total: number | null
          progress_percent: number | null
          publication_id: string | null
          remaining_lessons: number | null
          scope_type: string | null
          status: string | null
          title: string | null
        }
        Relationships: []
      }
      my_events: {
        Row: {
          branch_id: string | null
          created_at: string | null
          created_by: string | null
          department_id: string | null
          description: string | null
          event_end_at: string | null
          event_id: string | null
          event_scope: string | null
          event_start_at: string | null
          featured_image: string | null
          is_active: boolean | null
          latitude: number | null
          location: string | null
          longitude: number | null
          source_table: string | null
          title: string | null
        }
        Relationships: []
      }
      my_profile: {
        Row: {
          attendance_rate_percent: number | null
          avatar: string | null
          bio: string | null
          branch_id: string | null
          branch_name: string | null
          classes_in_progress_count: number | null
          courses_completed_count: number | null
          date_of_birth: string | null
          department_id: string | null
          department_name: string | null
          email: string | null
          emergency_contact: string | null
          first_name: string | null
          full_name: string | null
          gender: string | null
          is_verified: boolean | null
          last_name: string | null
          leadership_title: string | null
          marital_status: string | null
          maturity_class_completed: string | null
          member_id_display: string | null
          member_since: string | null
          membership_code: string | null
          ministry_class_completed: string | null
          mission_class_completed: string | null
          next_pending_class_meta: string | null
          next_pending_class_title: string | null
          occupation: string | null
          pending_classes_count: number | null
          phone: string | null
          queries_count: number | null
          residential_address: string | null
          role_name: string | null
          status_label: string | null
          user_id: string | null
          water_baptism_date: string | null
        }
        Relationships: []
      }
      my_queries: {
        Row: {
          acknowledged_at: string | null
          closed_at: string | null
          details: string | null
          escalates_at: string | null
          id: string | null
          needs_attention: boolean | null
          opened_at: string | null
          raised_by_department: string | null
          raised_by_name: string | null
          raised_by_user_id: string | null
          requires_acknowledgement: boolean | null
          requires_response: boolean | null
          responded_at: string | null
          response_text: string | null
          status: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: []
      }
      my_recurring_events: {
        Row: {
          branch_id: string | null
          created_at: string | null
          created_by: string | null
          day_of_month: number | null
          day_of_week: number | null
          department_id: string | null
          description: string | null
          end_time: string | null
          event_scope: string | null
          featured_image: string | null
          is_active: boolean | null
          month: number | null
          recurrence_type: string | null
          recurring_event_id: string | null
          source_table: string | null
          start_time: string | null
          title: string | null
          week_of_month: number | null
        }
        Relationships: []
      }
      posts_with_comments: {
        Row: {
          body: string | null
          branch_id: string | null
          branch_name: string | null
          comments: Json | null
          comments_count: number | null
          created_at: string | null
          created_by: string | null
          created_by_name: string | null
          department_id: string | null
          department_name: string | null
          id: string | null
          is_pinned: boolean | null
          modified_at: string | null
          modified_by: string | null
          modified_by_name: string | null
          post_archived: boolean | null
          post_more: Json | null
          reactions: Json | null
          target_type: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_modified_by_fkey"
            columns: ["modified_by"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
      profile_attendance_view: {
        Row: {
          branch_id: string | null
          closedlat: number | null
          closedlong: number | null
          created_at: string | null
          department_id: string | null
          event_id: string | null
          fullname: string | null
          id: string | null
          latitude: number | null
          longitude: number | null
          profile_avatar: string | null
          profile_branch_id: string | null
          profile_department_id: string | null
          profile_full_name: string | null
          profile_membership_code: string | null
          status: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["profile_branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["profile_branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["profile_department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["profile_department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["profile_department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      profile_view: {
        Row: {
          bio: string | null
          branch_id: string | null
          branch_id_confirm: string | null
          branch_name: string | null
          department_id: string | null
          department_id_confirm: string | null
          department_name: string | null
          firstname: string | null
          full_name: string | null
          lastname: string | null
          membership_code: string | null
          phone: string | null
          user_id: string | null
          worker_membershipcode: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
        ]
      }
      recurring_events: {
        Row: {
          created_at: string | null
          day_of_month: number | null
          day_of_week: number | null
          description: string | null
          end_time: string | null
          featured_url: string | null
          id: string | null
          is_active: boolean | null
          month: number | null
          recurrence_type: string | null
          start_time: string | null
          title: string | null
          week_of_month: number | null
        }
        Relationships: []
      }
      systemreports: {
        Row: {
          calculated_at: string | null
          data: Json | null
          report_type: string | null
        }
        Relationships: []
      }
      weekly_attendance_summary: {
        Row: {
          branch_id: string | null
          total_attendance: number | null
          unique_attendees: number | null
          week_start: string | null
        }
        Relationships: []
      }
      weekly_branch_stats: {
        Row: {
          branch_id: string | null
          events_this_week: number | null
          workers_attended: number | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
        ]
      }
      worker_profiles: {
        Row: {
          avatar: string | null
          bio: string | null
          branch_id: string | null
          branch_name: string | null
          date_joined: string | null
          department_id: string | null
          department_name: string | null
          firstname: string | null
          full_name: string | null
          lastname: string | null
          phone: string | null
          profile_created_at: string | null
          profile_id: string | null
          profile_membership_code: string | null
          user_id: string | null
          verified: boolean | null
          worker_created_at: string | null
          worker_id: string | null
          worker_membershipcode: string | null
        }
        Relationships: [
          {
            foreignKeyName: "workers_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["branch_id_confirm"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "department_summary_view"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["department_id_confirm"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profile_view"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "worker_profiles"
            referencedColumns: ["profile_id"]
          },
        ]
      }
    }
    Functions: {
      add_fullname_top_level_claim: { Args: { event: Json }; Returns: Json }
      add_wp_info_to_jwt: { Args: { event: Json }; Returns: Json }
      backfill_seed_auth_users: { Args: never; Returns: Json }
      can_manage_branch_scope_event: {
        Args: { target_branch_id: string }
        Returns: boolean
      }
      can_manage_department_scope_content: {
        Args: { target_branch_id: string; target_department_id: string }
        Returns: boolean
      }
      can_manage_department_scope_event: {
        Args: { target_branch_id: string; target_department_id: string }
        Returns: boolean
      }
      can_manage_global_scope_event: { Args: never; Returns: boolean }
      can_read_branch_scope_event: {
        Args: { target_branch_id: string }
        Returns: boolean
      }
      can_read_department_scope_event: {
        Args: { target_branch_id: string; target_department_id: string }
        Returns: boolean
      }
      churchmetric_academy_class_detail_v1: {
        Args: { p_course_id: string; p_session_id?: string }
        Returns: Json
      }
      churchmetric_academy_classes_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_academy_enrolments_v1: {
        Args: {
          p_branch_id?: string
          p_filter?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
        }
        Returns: Json
      }
      churchmetric_academy_instructors_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_session_id?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_add_target_progress: {
        Args: {
          p_delta: number
          p_idempotency_key: string
          p_source_id?: string
          p_source_type?: string
          p_target_id: string
        }
        Returns: {
          achieved: boolean
          value_after: number
        }[]
      }
      churchmetric_admin_context: { Args: never; Returns: Json }
      churchmetric_allocate_membership_code: {
        Args: never
        Returns: {
          display_code: string
          membership_code: string
        }[]
      }
      churchmetric_analytics_report_v1: {
        Args: {
          p_branch_id?: string
          p_category?: string
          p_end_at: string
          p_start_at: string
        }
        Returns: Json
      }
      churchmetric_assign_enquiry_v1: {
        Args: { p_enquiry_id: string; p_handler_id?: string }
        Returns: string
      }
      churchmetric_assign_quality_report: {
        Args: { p_assignee_id: string; p_report_id: string }
        Returns: undefined
      }
      churchmetric_branch_id: { Args: never; Returns: string }
      churchmetric_can_manage_branch: {
        Args: { target_branch: string }
        Returns: boolean
      }
      churchmetric_can_read_branch: {
        Args: { target_branch: string }
        Returns: boolean
      }
      churchmetric_claim_email_outbox: {
        Args: { p_limit?: number }
        Returns: {
          aggregate_id: string
          attempts: number
          available_at: string
          branch_id: string
          channel: string
          created_at: string
          event_type: string
          id: string
          idempotency_key: string
          last_error: string | null
          locked_at: string | null
          payload: Json
          processed_at: string | null
          status: string
        }[]
        SetofOptions: {
          from: "*"
          to: "notification_outbox"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      churchmetric_create_campaign: {
        Args: {
          p_body: string
          p_branch_id: string
          p_channel: string
          p_name: string
          p_recipients: Json
          p_scheduled_at: string
          p_subject: string
        }
        Returns: string
      }
      churchmetric_create_email_campaign_v1: {
        Args: {
          p_audience_category: string
          p_body: string
          p_branch_id: string
          p_name: string
          p_recipients: Json
          p_scheduled_at: string
          p_subject: string
        }
        Returns: string
      }
      churchmetric_create_quality_query: {
        Args: {
          p_assignee_ids: string[]
          p_body: string
          p_branch_id: string
          p_due_at: string
          p_priority: string
          p_subject: string
        }
        Returns: string
      }
      churchmetric_create_quality_query_v2: {
        Args: {
          p_assignee_ids: string[]
          p_body: string
          p_branch_id: string
          p_due_at: string
          p_issued_at: string
          p_priority: string
          p_subject: string
        }
        Returns: string
      }
      churchmetric_create_quality_query_v3: {
        Args: {
          p_assignee_ids: string[]
          p_body: string
          p_branch_id: string
          p_category: string
          p_due_at: string
          p_issued_at: string
          p_priority: string
          p_subject: string
        }
        Returns: string
      }
      churchmetric_create_soul_v1: {
        Args: {
          p_branch_id: string
          p_email?: string
          p_evangelist_name?: string
          p_event_id: string
          p_full_name: string
          p_location?: string
          p_phone?: string
        }
        Returns: string
      }
      churchmetric_create_target_v1: {
        Args: {
          p_branch_id: string
          p_current_value: number
          p_ends_at: string
          p_goal_value: number
          p_metric: string
          p_notification_channels: string[]
          p_period_label: string
          p_period_type: string
          p_progress_step: number
          p_starts_at: string
          p_title: string
        }
        Returns: string
      }
      churchmetric_department_detail_v1: {
        Args: {
          p_branch_id?: string
          p_department_id: string
          p_page?: number
          p_page_size?: number
          p_search?: string
        }
        Returns: Json
      }
      churchmetric_departments_report_v1: {
        Args: { p_branch_id?: string; p_search?: string }
        Returns: Json
      }
      churchmetric_enquiries_inbox_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_enquiry_thread_v1: {
        Args: { p_enquiry_id: string }
        Returns: Json
      }
      churchmetric_event_attendance_v1: {
        Args: {
          p_event_id: string
          p_page?: number
          p_page_size?: number
          p_search?: string
        }
        Returns: Json
      }
      churchmetric_event_souls_v1: {
        Args: {
          p_event_id: string
          p_page?: number
          p_page_size?: number
          p_search?: string
        }
        Returns: Json
      }
      churchmetric_events_report_v1: {
        Args: {
          p_branch_id?: string
          p_end_at: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_start_at: string
        }
        Returns: Json
      }
      churchmetric_followups_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_membership_overview: {
        Args: { p_branch_id?: string; p_end_at: string; p_start_at: string }
        Returns: Json
      }
      churchmetric_quality_issue_detail_v1: {
        Args: { p_issue_id: string }
        Returns: Json
      }
      churchmetric_quality_issues_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_priority?: string
          p_search?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_quality_queries_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_quality_report_detail_v1: {
        Args: { p_report_id: string }
        Returns: Json
      }
      churchmetric_quality_reports_inbox_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_source?: string
          p_status?: string
        }
        Returns: Json
      }
      churchmetric_reply_to_enquiry_v1: {
        Args: { p_body: string; p_enquiry_id: string }
        Returns: Json
      }
      churchmetric_role: { Args: never; Returns: string }
      churchmetric_set_enquiry_status_v1: {
        Args: { p_enquiry_id: string; p_status: string }
        Returns: string
      }
      churchmetric_soul_winning_report_v1: {
        Args: {
          p_branch_id?: string
          p_end_at: string
          p_page?: number
          p_page_size?: number
          p_search?: string
          p_start_at: string
        }
        Returns: Json
      }
      churchmetric_targets_v1: {
        Args: {
          p_branch_id?: string
          p_page?: number
          p_page_size?: number
          p_period?: string
          p_search?: string
        }
        Returns: Json
      }
      churchmetric_transition_quality_issue: {
        Args: { p_issue_id: string; p_next_status: string; p_note?: string }
        Returns: undefined
      }
      churchmetric_transition_quality_report: {
        Args: { p_action: string; p_report_id: string }
        Returns: string
      }
      churchmetric_transition_soul: {
        Args: { p_next_status: string; p_notes?: string; p_soul_id: string }
        Returns: undefined
      }
      create_scoped_event: {
        Args: {
          p_branch_id: string
          p_created_by: string
          p_department_ids: string[]
          p_description: string
          p_end_at: string
          p_featured_url: string
          p_latitude: number
          p_location: string
          p_longitude: number
          p_scope: string
          p_start_at: string
          p_title: string
        }
        Returns: Json
      }
      current_access_scope: {
        Args: never
        Returns: {
          auth_user_id: string
          branch_id: string
          can_read_branch_attendance: boolean
          can_read_department_attendance: boolean
          department_id: string
          is_global_admin: boolean
          is_member_only: boolean
          primary_role_name: string
          primary_scope_type: string
        }[]
      }
      current_my_classes: {
        Args: never
        Returns: {
          assigned_at: string
          available_from: string
          branch_id: string
          category: string
          certificate_available: boolean
          course_id: string
          department_id: string
          description: string
          due_at: string
          icon_key: string
          module_index: number
          module_total: number
          progress_percent: number
          publication_id: string
          remaining_lessons: number
          scope_type: string
          status: string
          title: string
        }[]
      }
      current_my_profile: {
        Args: never
        Returns: {
          attendance_rate_percent: number
          avatar: string
          bio: string
          branch_id: string
          branch_name: string
          classes_in_progress_count: number
          courses_completed_count: number
          date_of_birth: string
          department_id: string
          department_name: string
          email: string
          emergency_contact: string
          first_name: string
          full_name: string
          gender: string
          is_verified: boolean
          last_name: string
          leadership_title: string
          marital_status: string
          maturity_class_completed: string
          member_id_display: string
          member_since: string
          membership_code: string
          ministry_class_completed: string
          mission_class_completed: string
          next_pending_class_meta: string
          next_pending_class_title: string
          occupation: string
          pending_classes_count: number
          phone: string
          queries_count: number
          residential_address: string
          role_name: string
          status_label: string
          user_id: string
          water_baptism_date: string
        }[]
      }
      current_my_queries: {
        Args: never
        Returns: {
          acknowledged_at: string
          closed_at: string
          details: string
          escalates_at: string
          id: string
          needs_attention: boolean
          opened_at: string
          raised_by_department: string
          raised_by_name: string
          raised_by_user_id: string
          requires_acknowledgement: boolean
          requires_response: boolean
          responded_at: string
          response_text: string
          status: string
          title: string
          updated_at: string
          user_id: string
        }[]
      }
      current_primary_role_name: {
        Args: { target_user_id: string }
        Returns: string
      }
      current_user_branch: { Args: never; Returns: string }
      file_department_query: {
        Args: {
          query_details: string
          query_title: string
          target_user_id: string
        }
        Returns: string
      }
      get_current_rolename: { Args: never; Returns: string }
      get_current_user_branch: { Args: never; Returns: string }
      get_current_user_context: {
        Args: never
        Returns: {
          branch_id: string
          department_id: string
          role_name: string
          user_id: string
        }[]
      }
      get_current_user_department: { Args: never; Returns: string }
      get_current_user_id: { Args: never; Returns: string }
      get_current_user_role: { Args: never; Returns: string }
      get_my_branch: { Args: never; Returns: string }
      get_my_branch_id: { Args: never; Returns: string }
      get_my_department: { Args: never; Returns: string }
      get_my_role: { Args: never; Returns: string }
      get_profiles_view: {
        Args: never
        Returns: {
          address: string
          avatar: string
          branch_id: string
          created_at: string
          department: string
          department_id: string
          email: string
          full_name: string
          id: string
          lastname: string
          membership_code: string
          occupation: string
          phone: string
          role: string
          verified: boolean
        }[]
      }
      get_user_branch: { Args: never; Returns: string }
      get_user_branch_id: { Args: never; Returns: string }
      get_user_department: { Args: never; Returns: string }
      get_user_department_id: { Args: never; Returns: string }
      get_user_role: { Args: never; Returns: string }
      global_search: {
        Args: {
          limit_per_section?: number
          search_filter?: string
          search_query: string
        }
        Returns: {
          body: string
          id: string
          image_url: string
          metadata: Json
          rank: number
          result_type: string
          route: string
          section: string
          subtitle: string
          title: string
        }[]
      }
      is_admin: { Args: never; Returns: boolean }
      is_admin_or_global: { Args: never; Returns: boolean }
      is_globaladmin: { Args: never; Returns: boolean }
      is_self: { Args: { target_id: string }; Returns: boolean }
      posts_current_branch: { Args: { p_post_id: string }; Returns: string }
      posts_current_department: { Args: { p_post_id: string }; Returns: string }
      raise_member_queries: {
        Args: {
          p_attachment_url?: string
          p_details: string
          p_requires_response: boolean
          p_target_user_ids: string[]
          p_title: string
        }
        Returns: Json
      }
      relink_current_auth_profile: { Args: never; Returns: string }
      relink_profile_identity: {
        Args: {
          target_auth_user_id: string
          target_email?: string
          target_membership_code?: string
        }
        Returns: string
      }
      resolve_current_profile_identity: {
        Args: never
        Returns: {
          email: string
          is_direct_auth_match: boolean
          membership_code: string
          profile_user_id: string
        }[]
      }
      same_branch_as_current: {
        Args: { target_user_id: string }
        Returns: boolean
      }
      same_department_as_current: {
        Args: { target_user_id: string }
        Returns: boolean
      }
      search_text_rank: {
        Args: { candidate: string; term: string }
        Returns: number
      }
      sync_dept_leader_role_for_user: {
        Args: { target_user_id: string }
        Returns: undefined
      }
      sync_global_admin_role_for_user: {
        Args: { target_user_id: string }
        Returns: undefined
      }
      sync_recurring_events_for_week: {
        Args: { p_timezone?: string; p_week_start?: string }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
