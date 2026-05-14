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
- [ ] Improve the "Nearby" filter

---

# New Features & Implementations

## Business Accounts
- [ ] Improve and complete venue account creation for:
  - pubs
  - bars
  - restaurants
  - other venues

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
- [ ] Implement "Circles" for private events
  - [ ] Circles management UI (creation, editing, user management)
  - [ ] Circles selection during private event creation

## Profile & Account Management
- [x] Add profile deletion
- [x] Implement screens for blocked accounts:
  - ban
  - suspension
  - not_verified
- [ ] Display the event category badge based on the user's most attended event category

## Architecture & Standardization
- [x] Create a standard inside `vez_page_layout`
  to make top navbar buttons global
  and easier to manage

---

# 2nd Task List — Deadline: June 1st

## Event Role Management
- [x] Implement the "Co-Host" role (max. 5 per event)
- [x] Co-Host permissions:
  - invite users
  - remove invited users
  - view participant list
- [x] Restrict Co-Host permissions (NO event editing, NO event deletion)

## Expired Event UI
- [ ] Correctly retrieve the event category and type
- [ ] Complete the expired event UI in the "Past Events" dashboard

## Event Modification System
- [ ] Distinguish critical and non-critical changes
- [ ] Implement "Soft Lock"

## RSVP & Deadline System
- [ ] Implement "Response Deadline" (Time X)
- [ ] Automatic deadline calculation based on event distance
- [ ] Allow manual override by the Host
- [ ] Handle "Maybe" status after expiration
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

## Event Transparency
- [ ] Show "Last Updated"
- [ ] Implement Change Log
- [ ] Add UI badges for modifications

## Real UX Improvements
- [ ] Add Google Maps deep links in the event page
- [ ] Add direct navigation
- [ ] Improve RSVP clarity
- [ ] Improve Home Page auto-update system

## Nearby & Discovery
- [ ] Improve nearby events ranking
- [ ] Add advanced filters
- [ ] Improve search
- [ ] Create a map showing all events in the searched area

## Event Page
- [ ] Create the "Event Page" to display detailed information about selected events:
  - [ ] Google Maps deep link
  - [ ] Direct navigation
  - [ ] Improved RSVP clarity
  - [ ] Dedicated details section

---

# 3rd Task List — Deadline: TBD

## Achievement System
- [ ] Define the system
- [ ] Create achievements list
- [ ] Automatic assignment
- [ ] Profile UI
- [ ] Database saving

## Attendance Verification
- [ ] Define check-in method
- [ ] Save attendance status
- [ ] Implement anti-fake system
- [ ] Show attendance in profile
- [ ] Achievement integration

## Reputation System
- [ ] Event ratings
- [ ] Host ratings
- [ ] Last-minute modification penalties
- [ ] Host badges

## Post-Event Features
- [ ] Photo upload
- [ ] Events timeline
- [ ] Attended events history

## UI Improvements
- [ ] Dark / Light Mode switch

---

Luca Bisognin — Technical Lead  
Bologna, Italy — May 14, 2026

Vez — Social Event Platform  
Designed and developed by Outly