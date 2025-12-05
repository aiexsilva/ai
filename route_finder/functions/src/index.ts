import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";
import { isValidLocation, encodePolylinePoints } from "./utils";
import { defineSecret } from "firebase-functions/params";
import { v4 as uuidv4 } from 'uuid';

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

      const places = response.data.places || [];

      dlog("Places found: " + places.length);

      dlog("===== END: CREATE ROUTE WITH KEYWORDS =====");

      console.log(debugLog);

      return { places };

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

    const { selectedPlaces, start, end } = request.data as { selectedPlaces: any[], start: any, end: any };

    dlog("Selected places: " + JSON.stringify(selectedPlaces));
    dlog("Start: " + JSON.stringify(start));
    dlog("End: " + JSON.stringify(end));

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
        delete routeData.route;
      }

      const routeId = uuidv4();

      await db.collection("routes").doc(routeId).set({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: request.auth!.uid,
        routeId,
        start,
        end,
        waypoints: selectedPlacesArray,
        routeData,
      });

      await db.collection("users").doc(request.auth!.uid).update({
        routeIds: admin.firestore.FieldValue.arrayUnion(routeId),
      });

      dlog("Route created successfully.");
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

// cd functions
// npm run lint -- --fix
// cd ..
// firebase deploy --only functions