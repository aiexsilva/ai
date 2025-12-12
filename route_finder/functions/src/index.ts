import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";
import { isValidLocation, encodePolylinePoints, calculateTotalDistance, haversineDistance } from "./utils";
import geohash from "ngeohash";
import { defineSecret } from "firebase-functions/params";
import { v4 as uuidv4 } from 'uuid';

functions.setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

const db = admin.firestore();

const mapsApiKeySecret = defineSecret("GOOGLE_MAPS_API_KEY");

// ====== AUTHENTICATION ======
export const finalizeEmailRegistration = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {

    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: FINALIZE EMAIL REGISTRATION =====");

    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "The function must be called while authenticated.",
        );
      }

      dlog("Request data: " + JSON.stringify(request.data));

      const { uid, email } = request.data;

      dlog("UID: " + uid);
      dlog("Email: " + email);

      if (!uid || !email) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "The function must be called with a UID and email.",
        );
      }

      await db.collection("users").doc(uid).set({
        id: uid,
        email: email,
        routeIds: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      dlog("===== END: FINALIZE EMAIL REGISTRATION =====");

      console.log(debugLog);

      return { success: true };
    } catch (error) {
      console.error("Error finalizing email registration:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to finalize email registration.",
      );
    }
  }
);

// ====== ROUTE POLYLINE GENERATION ======
async function generateRoutePolylinesLogic(start: any, end: any, waypoints: any[], dlog: (msg: string) => void = console.log): Promise<any> {
  dlog("===== START: GENERATE ROUTE POLYLINES LOGIC =====");
  dlog("Start: " + JSON.stringify(start));
  dlog("End: " + JSON.stringify(end));
  dlog("Waypoints: " + JSON.stringify(waypoints));

  if (!start || !end) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a start and end location.",
    );
  }

  if (!isValidLocation(start) || !isValidLocation(end)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with valid start and end locations.",
    );
  }

  try {
    dlog("Calling route service...");

    const response = await axios.post(
      "https://getroutepolyline-634529947719.europe-southwest1.run.app/get_route",
      {
        start: { lat: start.coordinates.latitude, lng: start.coordinates.longitude },
        end: { lat: end.coordinates.latitude, lng: end.coordinates.longitude },
        waypoints: waypoints?.map((w: any) => ({
          lat: w.coordinates.latitude,
          lng: w.coordinates.longitude,
        })),
      }
    );

    dlog("Route service response: " + JSON.stringify(response.data));
    dlog("===== END: GENERATE ROUTE POLYLINES LOGIC =====");
    return response.data;
  } catch (error: any) {
    console.error("Error calling route service:", error.message);
    if (error.response) {
      console.error("Response data:", error.response.data);
      throw new functions.https.HttpsError(
        "internal",
        `Route service error: ${JSON.stringify(error.response.data)}`
      );
    }
    throw new functions.https.HttpsError(
      "internal",
      "Failed to generate route."
    );
  }
}

export const generateRoutePolylines = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {

    let debugLog = "";

    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: GENERATE ROUTE POLYLINES =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    dlog("Request data: " + JSON.stringify(request.data));

    const { start, end, waypoints } = request.data;

    try {
      const result = await generateRoutePolylinesLogic(start, end, waypoints, dlog);
      console.log(debugLog);
      return result;
    } catch (e) {
      console.log(debugLog);
      throw e;
    }
  }
);

// ====== ROUTE CREATION ======
export const createRouteWithKeywords = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB", secrets: ["GOOGLE_MAPS_API_KEY"] },
  async (request) => {

    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: CREATE ROUTE WITH KEYWORDS =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { keywords, start, radius } = request.data as { keywords: string[], start: any, radius: number };

    dlog("Keywords: " + JSON.stringify(keywords));
    dlog("Start: " + JSON.stringify(start));
    dlog("Radius: " + radius);

    if (!keywords) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with keywords.",
      );
    }

    if (!start || !isValidLocation(start)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid start location.",
      );
    }

    if (!radius || radius < 1000 || radius > 10000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid radius (1000m-10000m).",
      );
    }

    try {
      const MAX_KEYWORDS = 6;
      const keywordsToProcess = keywords.slice(0, MAX_KEYWORDS);
      const matchedCategories: string[] = [];

      dlog(`Processing ${keywordsToProcess.length} keywords...`);

      for (const keyword of keywordsToProcess) {
        try {
          dlog(`Calling microservice for keyword: ${keyword}`);
          const response = await axios.post(
            "https://match-keywords-634529947719.europe-southwest1.run.app",
            { keywords: [keyword] },
            { headers: { "Content-Type": "application/json" } }
          );

          if (response.data && response.data.category) {
            dlog(`Match found: ${response.data.category}`);
            matchedCategories.push(response.data.category);
          } else {
            dlog(`No match for: ${keyword}`);
          }
        } catch (err: any) {
          dlog(`Error matching keyword '${keyword}': ${err.message}`);
        }
      }

      // Remove duplicates
      const uniqueCategories = [...new Set(matchedCategories)];
      dlog("Unique matched categories: " + JSON.stringify(uniqueCategories));

      if (uniqueCategories.length === 0) {
        dlog("No categories matched. Returning empty list.");
        return { places: [] };
      }

      const mapsApiKey = mapsApiKeySecret.value();

      const response = await axios.post(
        "https://places.googleapis.com/v1/places:searchNearby",
        {
          includedTypes: uniqueCategories,
          maxResultCount: 10,
          locationRestriction: {
            circle: {
              center: {
                latitude: start.coordinates.latitude,
                longitude: start.coordinates.longitude,
              },
              radius: radius,
            },
          },
        },
        {
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": mapsApiKey,
            "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location,places.photos,places.rating,places.regularOpeningHours,places.types",
          },
        }
      );

      dlog("Places API result: " + JSON.stringify(response.data));

      const places = (response.data.places || []).map((place: any) => ({
        ...place,
        placeId: place.id,
      }));

      dlog("Places found: " + places.length);

      dlog("===== END: CREATE ROUTE WITH KEYWORDS =====");

      console.log(debugLog);

      dlog("Places found: " + places.length);

      // --- SENTIMENT ANALYSIS FILTERING ---
      try {
        dlog("Calling sentiment analysis microservice...");
        const sentimentServiceUrl = "https://filter-places-sentiment-634529947719.europe-southwest1.run.app/";

        const sentimentResponse = await axios.post(
          sentimentServiceUrl,
          { places: places },
          { headers: { "Content-Type": "application/json" } }
        );

        if (sentimentResponse.data && sentimentResponse.data.places) {
          const filteredPlaces = sentimentResponse.data.places;
          dlog(`Filtered places: ${filteredPlaces.length} (from ${places.length})`);
          return { places: filteredPlaces };
        } else {
          dlog("Sentiment service returned unexpected data. Returning original places.");
          return { places };
        }
      } catch (err: any) {
        dlog(`Error calling sentiment service: ${err.message}. Returning original places.`);
        // Fail open: if service fails, return original places
        return { places };
      }

    } catch (error: any) {
      console.error("Error calling places service:", error.message);
      if (error.response) {
        console.error("Response data:", error.response.data);
        throw new functions.https.HttpsError(
          "internal",
          `Places service error: ${JSON.stringify(error.response.data)}`
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get places."
      );
    }
  }
);

export const finalizeRouteCreation = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "512MiB", secrets: ["GOOGLE_MAPS_API_KEY"] },
  async (request) => {

    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: FINALIZE ROUTE CREATION =====");

    if (request.auth == null) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { name, selectedPlaces, start, end } = request.data as { name: string, selectedPlaces: any[], start: any, end: any };

    dlog("Name: " + name);
    dlog("Selected places: " + JSON.stringify(selectedPlaces));
    dlog("Start: " + JSON.stringify(start));
    dlog("End: " + JSON.stringify(end));

    if (!name) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a name.",
      );
    }

    if (!selectedPlaces || selectedPlaces.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with selected places.",
      );
    }

    if (!start || !isValidLocation(start)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid start location.",
      );
    }

    if (!end || !isValidLocation(end)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid end location.",
      );
    }

    const selectedPlacesArray: any[] = selectedPlaces.map((place: any) => {
      return {
        placeId: place.placeId,
        name: place.name,
        coordinates: {
          latitude: place.coordinates.latitude,
          longitude: place.coordinates.longitude,
        },
        rating: place.rating ?? null,
        photos: place.photos ?? [],
        types: place.types ?? [],
        openingHours: place.openingHours ?? null,
      };
    });

    if (selectedPlacesArray.length < 1) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with at least one selected place.",
      );
    }

    if (selectedPlacesArray.length > 10) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with at most 10 selected places.",
      );
    }

    try {
      const routeData = await generateRoutePolylinesLogic(start, end, selectedPlacesArray, dlog);
      dlog("Route generated successfully.");

      if (routeData.route) {
        const encodedPolyline = await encodePolylinePoints(routeData.route);
        routeData.encodedPolyline = encodedPolyline;

        // calculate total distance
        const totalDistance = await calculateTotalDistance(routeData.route);
        routeData.totalDistance = totalDistance;

        dlog("Total distance: " + totalDistance);

        delete routeData.route;
      }

      const routeId = uuidv4();
      const publicRouteId = uuidv4();

      // Calculate center for geohash
      const centerLat = (start.coordinates.latitude + end.coordinates.latitude) / 2;
      const centerLng = (start.coordinates.longitude + end.coordinates.longitude) / 2;
      const geohashString = geohash.encode(centerLat, centerLng, 4); // Precision 4 is ~20km

      const now = admin.firestore.FieldValue.serverTimestamp();

      // Create Public Route
      const publicRouteData = {
        name,
        createdAt: now,
        updatedAt: now,
        createdBy: request.auth!.uid,
        routeId: publicRouteId,
        start,
        end,
        waypoints: selectedPlacesArray,
        routeData,
        isPublic: true,
        geohash: geohashString,
        originalCreatorId: request.auth!.uid,
        ratings: [],
      };

      await db.collection("routes").doc(publicRouteId).set(publicRouteData);

      // Create Private Route (Copy)
      const privateRouteData = {
        name,
        createdAt: now,
        updatedAt: now,
        createdBy: request.auth!.uid,
        routeId: routeId,
        start,
        end,
        waypoints: selectedPlacesArray,
        routeData,
        isPublic: false,
        publicRouteId: publicRouteId,
        currentWaypointIndex: 0,
        status: 'planned', // Default status
      };

      await db.collection("routes").doc(routeId).set(privateRouteData);

      await db.collection("users").doc(request.auth!.uid).update({
        routeIds: admin.firestore.FieldValue.arrayUnion(routeId),
      });

      dlog("Route created successfully (Public ID: " + publicRouteId + ", Private ID: " + routeId + ")");
      dlog("===== END: FINALIZE ROUTE CREATION =====");

      console.log(debugLog);

      return {
        success: true,
        routeId: routeId,
      }

    } catch (e: any) {
      dlog("Error generating route: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      }
    }
  }
);

export const getCommunityRoutes = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: GET COMMUNITY ROUTES =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { location, radius } = request.data as { location: any, radius: number };

    if (!location || !isValidLocation(location)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid location.",
      );
    }

    // Default radius 10km if not provided, max 50km
    const searchRadius = radius ? Math.min(Math.max(radius, 1000), 50000) : 10000;

    try {
      // Calculate geohash for the center
      const centerLat = location.coordinates.latitude;
      const centerLng = location.coordinates.longitude;
      const geohashString = geohash.encode(centerLat, centerLng, 4);

      dlog(`Searching for routes with geohash: ${geohashString}`);

      const routesRef = db.collection("routes");
      const snapshot = await routesRef
        .where("isPublic", "==", true)
        .where("geohash", "==", geohashString)
        .limit(20)
        .get();

      dlog(`Found ${snapshot.docs.length} routes`);

      const routes = snapshot.docs
        .map(doc => doc.data())
        .filter(route => {

          dlog(`Route: ${JSON.stringify(route)}`);

          if (!route.start || !route.start.coordinates) {
            dlog("Route has no start location");
            return false;
          }

          const distance = haversineDistance(
            location.coordinates,
            route.start.coordinates
          );

          dlog(`Distance: ${distance}`);

          return distance <= searchRadius;
        });

      dlog(`Filtered routes: ${routes.length}`);

      console.log(debugLog);

      return { routes };

    } catch (e: any) {
      dlog("Error getting community routes: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      };
    }
  }
);

export const saveCommunityRoute = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: SAVE COMMUNITY ROUTE =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    dlog(`User ID: ${request.auth.uid}`);

    const { publicRouteId } = request.data as { publicRouteId: string };

    if (!publicRouteId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a publicRouteId.",
      );
    }

    dlog(`Public Route ID: ${publicRouteId}`);

    try {
      const publicRouteSnap = await db.collection("routes").doc(publicRouteId).get();

      if (!publicRouteSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "The public route does not exist.",
        );
      }

      dlog(`Public Route Data: ${JSON.stringify(publicRouteSnap.data())}`);

      const publicRouteData = publicRouteSnap.data();

      if (!publicRouteData?.isPublic) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "The specified route is not public.",
        );
      }

      const newRouteId = uuidv4();
      const now = admin.firestore.FieldValue.serverTimestamp();

      const privateRouteData = {
        ...publicRouteData,
        routeId: newRouteId,
        createdBy: request.auth.uid,
        createdAt: now,
        updatedAt: now,
        isPublic: false,
        publicRouteId: publicRouteId,
        currentWaypointIndex: 0,
        status: 'planned',
        ratings: [],
        geohash: null,
      };

      delete (privateRouteData as any).id;

      await db.collection("routes").doc(newRouteId).set(privateRouteData);

      await db.collection("users").doc(request.auth.uid).update({
        routeIds: admin.firestore.FieldValue.arrayUnion(newRouteId),
      });

      dlog("Route saved successfully. New Private ID: " + newRouteId);
      dlog("===== END: SAVE COMMUNITY ROUTE =====");
      console.log(debugLog);

      return {
        success: true,
        routeId: newRouteId,
      };

    } catch (e: any) {
      dlog("Error saving community route: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      };
    }
  }
);

export const deleteRoute = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: DELETE ROUTE =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { routeId } = request.data as { routeId: string };

    dlog("Route ID: " + routeId);

    if (!routeId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid route ID.",
      );
    }

    try {

      const routeSnap = await db.collection("routes").doc(routeId).get();
      if (!routeSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "The route does not exist.",
        );
      }

      const routeData = routeSnap.data();
      if (routeData?.createdBy !== request.auth!.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not authorized to delete this route.",
        );
      }

      await db.collection("routes").doc(routeId).delete();
      await db.collection("users").doc(request.auth!.uid).update({
        routeIds: admin.firestore.FieldValue.arrayRemove(routeId),
      });
      dlog("Route deleted successfully.");
      dlog("===== END: DELETE ROUTE =====");
      console.log(debugLog);
      return {
        success: true,
        routeId: routeId,
      }
    } catch (e: any) {
      dlog("Error deleting route: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      }
    }
  }
);

export const updateRouteStatus = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: UPDATE ROUTE STATUS =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { routeId, status } = request.data as { routeId: string, status: string };

    dlog("Route ID: " + routeId);
    dlog("Status: " + status);

    if (!routeId || !status) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a route ID and status.",
      );
    }

    try {
      const routeRef = db.collection("routes").doc(routeId);
      const routeSnap = await routeRef.get();

      if (!routeSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "The route does not exist.",
        );
      }

      const routeData = routeSnap.data();
      if (routeData?.createdBy !== request.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not authorized to update this route.",
        );
      }

      if (status == 'active') {
        const waypoints = routeData.waypoints;

        waypoints.forEach((waypoint: any) => {
          waypoint.skipped = false;
          waypoint.visited = false;
        });

        await routeRef.update({
          currentWaypointIndex: 0,
          waypoints: waypoints,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await routeRef.update({
        status: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      dlog("Route status updated successfully.");
      dlog("===== END: UPDATE ROUTE STATUS =====");
      console.log(debugLog);
      return { success: true };
    } catch (e: any) {
      dlog("Error updating route status: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      };
    }
  }
);

export const updateWaypointStatus = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: UPDATE WAYPOINT STATUS =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { routeId, waypointIndex, visited, skipped } = request.data as {
      routeId: string,
      waypointIndex: number,
      visited: boolean,
      skipped: boolean
    };

    dlog(`Route ID: ${routeId}, Index: ${waypointIndex}, Visited: ${visited}, Skipped: ${skipped}`);

    if (!routeId || waypointIndex === undefined) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a route ID and waypoint index.",
      );
    }

    try {
      const routeRef = db.collection("routes").doc(routeId);
      const routeSnap = await routeRef.get();

      if (!routeSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "The route does not exist.",
        );
      }

      const routeData = routeSnap.data();
      if (routeData?.createdBy !== request.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You are not authorized to update this route.",
        );
      }

      const waypoints = routeData?.waypoints || [];
      if (waypointIndex < 0 || waypointIndex >= waypoints.length) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid waypoint index.",
        );
      }

      // Update the specific waypoint
      waypoints[waypointIndex].visited = visited;
      waypoints[waypointIndex].skipped = skipped;

      await routeRef.update({
        waypoints: waypoints,
        currentWaypointIndex: waypointIndex + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      dlog("Waypoint status updated successfully.");
      dlog("===== END: UPDATE WAYPOINT STATUS =====");
      console.log(debugLog);
      return { success: true };
    } catch (e: any) {
      dlog("Error updating waypoint status: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      };
    }
  }
);

export const rateRoute = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: RATE ROUTE =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { routeId, routeRating, routeReview, placesRatings } = request.data as {
      routeId: string,
      routeRating: number,
      routeReview?: string,
      placesRatings: { placeId: string, rating: number, review?: string }[]
    };

    dlog(`Route ID: ${routeId}, Rating: ${routeRating}`);
    dlog(`Places Ratings: ${JSON.stringify(placesRatings)}`);

    if (!routeId || !routeRating) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a route ID and route rating.",
      );
    }

    try {
      // 1. Update Route Rating
      // Check if we are rating a private route, if so, find the public route
      let targetRouteId = routeId;
      const routeRef = db.collection("routes").doc(routeId);
      const routeSnap = await routeRef.get();

      if (!routeSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "The route does not exist.",
        );
      }

      const routeData = routeSnap.data();
      if (routeData && !routeData.isPublic && routeData.publicRouteId) {
        dlog(`Rating private route ${routeId}, redirecting to public route ${routeData.publicRouteId}`);
        targetRouteId = routeData.publicRouteId;
      }

      const targetRouteRef = db.collection("routes").doc(targetRouteId);

      const routeRatingData = {
        rating: routeRating,
        review: routeReview || "",
        userId: request.auth.uid,
        timestamp: admin.firestore.Timestamp.now(),
      };

      await targetRouteRef.update({
        ratings: admin.firestore.FieldValue.arrayUnion(routeRatingData),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      dlog("Route rating updated.");

      // 2. Update Places Ratings
      if (placesRatings && placesRatings.length > 0) {
        const batch = db.batch();

        for (const placeRating of placesRatings) {
          if (!placeRating.placeId || !placeRating.rating) continue;

          const placeRef = db.collection("places").doc(placeRating.placeId);
          const placeRatingData = {
            rating: placeRating.rating,
            review: placeRating.review || "",
            userId: request.auth.uid,
            timestamp: admin.firestore.Timestamp.now(),
          };

          const now = admin.firestore.FieldValue.serverTimestamp();
          batch.set(placeRef, {
            ratings: admin.firestore.FieldValue.arrayUnion(placeRatingData),
            updatedAt: now,
          }, { merge: true });
        }

        await batch.commit();
        dlog("Places ratings updated.");
      }

      dlog("===== END: RATE ROUTE =====");
      console.log(debugLog);
      return { success: true };

    } catch (e: any) {
      dlog("Error rating route: " + e);
      console.error(debugLog);
      return {
        success: false,
        error: e.message,
      };
    }
  }
);