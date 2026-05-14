# Vez ToDos

---
# 1st Task List — Deadline: May 15th
---

# Bug Fixes

- [x] Fix the title length counter bug during event creation
- [x] Fully clean the user session and fix the notification bug that sends notifications to previously logged-in accounts
- [x] In the notifications page, the user must immediately see the updated selection and remain on the same page
- [x] Center the "Delete Event" button in the event edit page without moving the other page elements

---

# UI / UX Improvements

## Event Creation & Event UI

- [x] Improve location selection during event creation and specify that the map should be used to display the event in "Nearby"
- [x] Improve the event preview graphics for "By You" events following the mockup style
- [x] Complete the preview UI for "Invited" and "Nearby" events
- [x] Force the user to change the background image during event creation
- [x] Add guest limit number and price to carousel cards also in the "Yours" group
- [x] "Expired" event after the event date has passed:
  - [x] shown in the dashboard
  - [x] removed from carousels ("Invites", "Yours", "Nearby")

## Profile & Settings

- [x] Improve the profile page UI
- [x] Remove password change from profile editing and lighten the profile image border
- [x] Improve settings and add password change inside the "User" settings section
- [x] The top-right button in the profile page opens profile editing
- [x] Profile info should only display:
  - username
  - city
  - bio
  - profile picture
- [x] Disable click actions on profile information

## General UI Improvements

- [x] Improve popups by increasing blur and lowering background opacity
- [x] Improve popup menus for adding and managing guests
- [x] Improve language labels/texts
- [x] Remove the "Add Guests" button from public event previews
- [x] Set "Invited" events as primary in the "Home Page"
- [x] Add automatic refresh in the "Home Page" every X seconds
- [ ] Improve the "Nearby" filter

---

# New Features & Implementations

## Business Accounts

- [ ] Improve and complete account creation for venues:
  - pubs
  - bars
  - restaurants
  - other venues

## Social Features

- [x] Allow invited users to see other invited users for a specific event
- [x] Add user data and interactions:
  - [x] follow / follow back / unfollow
  - [x] unlock "friendship" status on mutual following
  - [x] followers count
  - [x] created events count
  - [x] attended events count
  - [x] received likes count on own events
  - [x] display any user's profile when clicking their profile picture
- [ ] Implement "Circles" for "Private" events
- [ ] Circles management UI (creation, editing, adding users)
- [ ] Implement Circles selection during Private event creation

## Profile & Account Management

- [x] Add profile deletion
- [x] Implement the screen for blocked accounts:
  - ban
  - suspension
  - not_verified

## Architecture & Standardization

- [x] Create a standard inside `vez_page_layout`
  to make top navbar buttons global
  and easier to modify

---

# 2nd Task List — Post May 15th

## Event Role Management

- [x] Implement "Co-Host" role (max. 5 per event)
- [x] Co-Host permissions:
  - invite users
  - remove invited users
  - view participant list
- [x] Restrict Co-Host permissions (NO event editing, NO event deletion)

## RSVP & Deadline System

- [ ] Implement "Response Deadline" (Time X)
- [ ] Automatic deadline calculation based on event distance
- [ ] Allow manual override by the Host
- [ ] Handle "Maybe" status after expiration
- [ ] Event deadline countdown UI

## Event Modification System

- [ ] Distinguish critical / non-critical changes
- [ ] Implement "Soft Lock"

## Last-Minute Changes

- [ ] Allow override changes after deadline
- [ ] Host warning popup
- [ ] Instant notification for critical changes
- [ ] Specific notifications (location, time, price)

## User Reactions

- [ ] Reset user status on critical changes
- [ ] Participation reconfirmation button
- [ ] Highlight modifications

## Event Transparency

- [ ] Show "Last Updated"
- [ ] Implement Change Log
- [ ] UI badges for modifications

## Real UX Improvements

- [ ] Google Maps deep links
- [ ] Direct navigation
- [ ] Improve RSVP clarity

## Nearby & Discovery

- [ ] Nearby events ranking
- [ ] Advanced filters
- [ ] Improve search
- [ ] Create a map showing all events in the searched area

---

# 3rd Task List — Deadline: June 1st

## Achievement System

- [ ] Define the system
- [ ] Create achievements list
- [ ] Automatic assignment
- [ ] Profile UI
- [ ] Database saving

## Attendance Verification

- [ ] Check-in method
- [ ] Save attendance status
- [ ] Anti-fake system
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
- [ ] Attended events

## UI Improvements

- [ ] Dark/Light Mode switch