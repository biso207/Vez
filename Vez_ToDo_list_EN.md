### Vez is a social platform focused on real-world events and user interaction.
### This document contains the current development roadmap and implemented features.

# Roadmap 2026

---

# 1st Task List — Deadline: May 15th

---

# Bug Fixes
- [x] Fix the title length counter bug during event creation
- [x] Fully clean the user session and fix the notification bug that sends notifications to previously logged-in accounts
- [x] In the notifications page, users must immediately see updated selections while remaining on the same page
- [x] Centre the "Delete Event" button on the event edit page without moving other page elements

---

# UI / UX Improvements

## Event Creation & Event UI
- [x] Improve location selection during event creation and specify that the map is used to display the event in "Nearby"
- [x] Improve the event preview graphics for "Yours" events following the mockup style
- [x] Complete the preview UI for "Invites" and "Nearby" events
- [x] Force users to change the background image during event creation
- [x] Add guest limit and price information to carousel cards in the "Yours" section
- [x] Handle expired events after the event date has passed:
  - [x] Show expired events in the dashboard
  - [x] Remove expired events from carousels ("Invites", "Yours", "Nearby")
- [x] Change default background image during event creation
- [x] Set the max length of the event title to 20 chars

## Profile & Settings
- [x] Improve the profile page UI
- [x] Remove password change from profile editing and lighten the profile image border
- [x] Improve settings and move password change into the "User" settings section
- [x] Make the top-right button in the profile page open profile editing
- [x] Limit visible profile information to:
  - username
  - city
  - bio
  - profile picture
- [x] Disable click actions on profile information

## General UI Improvements
- [x] Improve popups by increasing blur and lowering background opacity
- [x] Improve popup menus for adding and managing guests
- [x] Improve language labels and texts
- [x] Remove the "Add Guests" button from public event previews
- [x] Set "Invites" events as the primary section on the Home Page
- [x] Add automatic refresh on the Home Page every X seconds

---

# New Features & Implementations

## Business Accounts
- [x] Improve and complete venue account creation

## Social Features
- [x] Allow invited users to see other invited users for a specific event
- [x] Add user data and social interactions:
  - [x] follow / follow back / unfollow
  - [x] unlock "friendship" status on mutual following
  - [x] followers count
  - [x] created events count
  - [x] attended events count
  - [x] received likes count on owned events
  - [x] display any user's profile when clicking their profile picture

## Profile & Account Management
- [x] Add profile deletion
- [x] Implement screens for blocked accounts:
  - ban
  - suspension
  - not_verified
- [x] Display the event category badge based on the user's most attended event category
- [x] Not display the event category badge if the user has 0 past events
- [x] Lock the category badge toggle in settings when the category badge is disabled

## Architecture & Standardization
- [x] Create a standard inside `vez_page_layout`
  to make top navbar buttons global
  and easier to manage

---

# 2nd Task List — Deadline: June 1st

---

# Bug Fixes
- [ ] Find a better spot for the event delete button, now it appears under the bottom navbar in some devices.

---

# Event Architecture and UI Improvements

## Event Role Management
- [x] Implement the "Co-Host" role (max. 5 per event)
- [x] Co-Host permissions:
  - invite users
  - remove invited users
  - view participant list
- [x] Restrict Co-Host permissions (NO event editing, NO event deletion)

## Event Creation & Event UI
- [x] Correctly retrieve the event category and type for the events in the user dashboard
- [x] Complete the expired event UI in the "Past Events" dashboard
- [ ] Improve the Map general UI in the location setting during the event creation

## Event Modification System
- [ ] Distinguish critical and non-critical changes
- [ ] Implement "Soft Lock"

## Event Transparency
- [ ] Show "Last Updated"
- [ ] Implement Change Log
- [ ] Add UI badges for modifications

## Event Page
- [ ] Create the "Event Page" to display detailed information about selected events:
  - [ ] Google Maps deep link (opens Google Maps)
  - [ ] Improved RSVP clarity
  - [ ] Dedicated details section

---

# New Features & Implementations

## Advanced Search Button
- [ ] Implement the advanced "Search" filter:
  - [ ] Dedicated UI when clicked the "search box" in the top navbar
  - [ ] Complete research across the whole app ecosystem
  - [ ] Research based on usernames, venues name, events names, events locations, etc.
  - [ ] Sections in the dedicated UI for Users (friends, following, all), Events & Venues
  - [ ] Possibility to interact with the results in the dedicated UI

## Profile & Account Management
- [ ] Show the list of followers and friends from the profile screen of local and general user
- [ ] Complete the Profile Page for the venue with:
  - [ ] Details about the venue
  - [ ] Social Media platforms and Website links
  - [ ] Others important features and details

## 'Circles' Feature
- [ ] Implement "Circles" for "Private" events
  - [ ] Circles management UI (creation, editing, user management)
  - [ ] Circles selection during "Private" event creation

## RSVP & Deadline System
- [ ] Implement "Response Deadline" (Time X)
- [ ] Allow manual "Response Deadline" by the Host
- [ ] Handle "Maybe" status after expiration by setting the status as "Not Going"
- [ ] Add event deadline countdown UI

## Last-Minute Changes
- [ ] Allow override changes after deadline
- [ ] Add Host warning popup
- [ ] Instant notifications for critical changes
- [ ] Specific notifications (location, time, price)

## User Reactions
- [ ] Reset user status on critical changes
- [ ] Add participation reconfirmation button
- [ ] Highlight modifications

## Real UX Improvements
- [ ] Improve Home Page auto-update system

## Nearby & Discovery
- [ ] Improve the range distance filter
- [ ] Improve nearby events ranking
- [ ] Add advanced filters
- [ ] Improve search
- [ ] Create a map showing all events in the "Nearby" area

## Venue Verification System
- [ ] Implement venue verification request system
- [ ] Manual review process for venue accounts
- [ ] Add verification badge for approved venues
- [ ] Prevent fake business accounts and spam
- [ ] Require additional business information for verification
- [ ] Add moderation tools for suspicious venue activity

---

# 3rd Task List — Deadline: TBD

## Achievement System
- [ ] Define the system
- [ ] Create achievements list
- [ ] Automatic assignment
- [ ] Archived badges shown in the profile
- [ ] Database saving

## Attendance Verification
- [ ] Define check attendance method
- [ ] Save attendance status
- [ ] Implement anti-fake system
- [ ] Show attendance in profile
- [ ] Achievement integration

## Reputation System
- [ ] Event ratings
- [ ] Host ratings
- [ ] Host badges

## Post-Event Features
- [ ] Photo upload
- [ ] Events timeline
- [ ] Attended events history

## UI Improvements
- [ ] Dark / Light Mode switch

## Age Restriction & Safety System
- [ ] Define minimum platform age requirements
- [ ] Add optional event age restriction system:
  - [ ] All Ages
  - [ ] 16+
  - [ ] 18+
- [ ] Add age restriction badges inside event previews
- [ ] Add age restriction banner inside event pages
- [ ] Add filtering system for restricted events
- [ ] Limit event visibility based on user age settings
- [ ] Add warnings for adult or sensitive events
- [ ] Add moderation checks for restricted event categories

## Content & User Generated Media
- [ ] Define user responsibility for uploaded backgrounds and images
- [ ] Add copyright disclaimer for uploaded content
- [ ] Add image reporting system
- [ ] Add automatic NSFW / unsafe image moderation research
- [ ] Add content moderation flow for reported media

## Legal & GDPR Compliance
- [ ] Create Terms & Conditions
- [ ] Create Privacy Policy
- [ ] Add legal acceptance checkbox during signup
- [ ] Add Terms & Conditions page inside settings
- [ ] Add Privacy Policy page inside settings
- [ ] Add account deletion policy section
- [ ] Add support / legal contact email
- [ ] Specify how user data is collected, stored and processed
- [ ] Specify Supabase infrastructure and EU server location
- [ ] Define user responsibilities for uploaded content
- [ ] Define prohibited content and platform violations
- [ ] Define Host responsibilities for created events
- [ ] Define moderation and suspension policies
- [ ] Add report system for users and events
- [ ] Add content removal management system

---

Luca Bisognin — Software & Design Team Lead
Bologna, Italy — May 14, 2026

Vez — Social Event Platform  
Designed and developed by Outly

---
