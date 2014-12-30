
class BezierCurve implements IVectorFunction {
  int POLYLINE_POINTS_PER_CONTROL = 100;

  ArrayList<LineSegment> controls;

  int numPolylinePoints;
  float polylineLength;
  float[] polylineTimes;
  float[] polylineLengths;
  float[] segmentLengths;


  BezierCurve() {
    controls = new ArrayList<LineSegment>();

    numPolylinePoints = 0;
    polylineLength = 0;
  }

  void draw(PGraphics g) {
    LineSegment line0, line1;
    for (int i = 0; i < controls.size () - 1; i++) {
      line0 = controls.get(i);
      line1 = controls.get(i + 1);

      if (i == 0) {
        g.bezier(
        line0.p0.x, line0.p0.y, line0.p1.x, line0.p1.y,
        line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
      } else {
        g.bezier(
        line0.p1.x, line0.p1.y, 2 * line0.p1.x - line0.p0.x, 2 * line0.p1.y - line0.p0.y,
        line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
      }
    }
  }

  void draw(PGraphics g, float t0, float t1) {
    LineSegment line0, line1;
    float dist0 = t0 * polylineLength;
    float dist1 = t1 * polylineLength;
    float polylineDistance = 0;
    float segmentDistance = 0, nextSegmentDistance = segmentLengths[0];
    int prevControlIndex = 0;

    // FIXME: Inefficient to instantiate a BezierSegment during draw.
    BezierSegment bs;


    for (int i = 0; i < numPolylinePoints; i++) {
      int controlIndex = floor(polylineTimes[i] * (controls.size() - 1));
      if (prevControlIndex < controlIndex) {

        line0 = controls.get(prevControlIndex);
        line1 = controls.get(prevControlIndex + 1);

        if (dist0 < nextSegmentDistance && dist1 > segmentDistance) {
          // FIXME: Refactor.
          if (dist0 <= segmentDistance) {
            if (dist1 >= nextSegmentDistance) {
              if (prevControlIndex == 0) {
                g.bezier(
                line0.p0.x, line0.p0.y, line0.p1.x, line0.p1.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              } else {
                g.bezier(
                line0.p1.x, line0.p1.y, 2 * line0.p1.x - line0.p0.x, 2 * line0.p1.y - line0.p0.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              }
            } else {
              // Partial segment from 0 to dist1.
              if (prevControlIndex == 0) {
                bs = new BezierSegment(
                line0.p0.x, line0.p0.y, line0.p1.x, line0.p1.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              } else {
                bs = new BezierSegment(
                line0.p1.x, line0.p1.y, 2 * line0.p1.x - line0.p0.x, 2 * line0.p1.y - line0.p0.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              }
              bs.draw(g, 0, (dist1 - segmentDistance) / (segmentLengths[prevControlIndex]));
            }
          } else {
            if (dist1 >= nextSegmentDistance) {
              // Partial segment from dist0 to 1.
              if (prevControlIndex == 0) {
                bs = new BezierSegment(
                line0.p0.x, line0.p0.y, line0.p1.x, line0.p1.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              } else {
                bs = new BezierSegment(
                line0.p1.x, line0.p1.y, 2 * line0.p1.x - line0.p0.x, 2 * line0.p1.y - line0.p0.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              }
              bs.draw(g, (dist0 - segmentDistance) / (segmentLengths[prevControlIndex]), 1);
            } else {
              // Partial segment from dist0 to dist1.
              if (prevControlIndex == 0) {
                bs = new BezierSegment(
                line0.p0.x, line0.p0.y, line0.p1.x, line0.p1.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              } else {
                bs = new BezierSegment(
                line0.p1.x, line0.p1.y, 2 * line0.p1.x - line0.p0.x, 2 * line0.p1.y - line0.p0.y,
                line1.p0.x, line1.p0.y, line1.p1.x, line1.p1.y);
              }
              bs.draw(g, (dist0 - segmentDistance) / (segmentLengths[prevControlIndex]), (dist1 - segmentDistance) / (segmentLengths[prevControlIndex]));
            }
          }
        }

        prevControlIndex = controlIndex;
        segmentDistance += segmentLengths[controlIndex - 1];
        nextSegmentDistance = segmentDistance + segmentLengths[controlIndex];
      }

      if (i < numPolylinePoints - 1) {
        polylineDistance += polylineLengths[i];
      }
    }
  }

  int numControls() {
    return controls.size();
  }

  BezierSegment getSegment(int i) {
    if (i < 0 || i + 1 >= controls.size()) return null;
    return new BezierSegment(controls.get(i), controls.get(i + 1));
  }

  void addControl(LineSegment control) {
    controls.add(control);
    recalculate();
  }

  void drawControls(PGraphics g) {
    LineSegment line;
    for (int i = 0; i < controls.size (); i++) {
      line = controls.get(i);
      g.line(line.p0.x, line.p0.y, line.p1.x, line.p1.y);

      if (i > 0 && i < controls.size() - 1) {
        g.line(line.p1.x, line.p1.y, 2 * line.p1.x - line.p0.x, 2 * line.p1.y - line.p0.y);
      }
    }
  }

  float getLength() {
    if (controls.size() < 2) return 0;

    // FIXME: Use uniform arc-distance points for better accuracy.
    return polylineLength;
  }

  PVector getPoint(float t) {
    if (controls.size() < 2) return null;
    if (t <= 0) return controls.get(0).p0.get();
    if (t >= 1) return controls.get(controls.size() - 1).p1.get();

    float polylineDistance = 0;
    for (int i = 0; i < numPolylinePoints - 1; i++) {
      if (t * polylineLength < polylineDistance + polylineLengths[i]) {
        float k = (t * polylineLength - polylineDistance) / polylineLengths[i];
        float u = polylineTimes[i] + k * (polylineTimes[i + 1] - polylineTimes[i]);

        return getPointOnCurveNaive(u);
      }
      polylineDistance += polylineLengths[i];
    }

    return null;
  }

  /**
   * @see http://stackoverflow.com/a/4060392
   * @author michal@michalbencur.com
   */
  private float bezierInterpolation(float a, float b, float c, float d, float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return a + (-a * 3 + t * (3 * a - a * t)) * t
      + (3 * b + t * (-6 * b + b * 3 * t)) * t
      + (c * 3 - c * 3 * t) * t2
      + d * t3;
  }

  private int getPointOnCurveNaiveIndex(float t) {
    if (controls.size() < 1) return -1;
    int len = controls.size() - 1;
    int index = floor(t * len);
    return index;
  }

  private PVector getPointOnCurveNaive(float t) {
    if (controls.size() < 2) return null;
    if (t <= 0) return controls.get(0).p0.get();
    if (t >= 1.0) return controls.get(controls.size() - 1).p1.get();

    int len = controls.size() - 1;
    int index = floor(t * len);
    float u = (t * len - index);
    LineSegment line0 = controls.get(index);
    LineSegment line1 = controls.get(index + 1);
    if (index == 0) {
      return new PVector(
      bezierInterpolation(line0.p0.x, line0.p1.x, line1.p0.x, line1.p1.x, u),
      bezierInterpolation(line0.p0.y, line0.p1.y, line1.p0.y, line1.p1.y, u));
    } else {
      return new PVector(
      bezierInterpolation(line0.p1.x, 2 * line0.p1.x - line0.p0.x, line1.p0.x, line1.p1.x, u),
      bezierInterpolation(line0.p1.y, 2 * line0.p1.y - line0.p0.y, line1.p0.y, line1.p1.y, u));
    }
  }

  private void recalculate() {
    if (controls.size() < 2) return;

    numPolylinePoints = controls.size() * POLYLINE_POINTS_PER_CONTROL;
    PVector[] polylinePoints = new PVector[numPolylinePoints];
    int[] polylineControlIndices = new int[numPolylinePoints];
    polylineTimes = new float[numPolylinePoints];
    polylineLengths = new float[numPolylinePoints - 1];
    polylineLength = 0;
    segmentLengths = new float[controls.size()];
    int polylineControlIndex, prevPolylineControlIndex = -1;
    PVector d;

    for (int i = 0; i < numPolylinePoints; i++) {
      polylineTimes[i] = (float)i / (numPolylinePoints - 1);
      polylinePoints[i] = getPointOnCurveNaive(polylineTimes[i]);
      polylineControlIndex = polylineControlIndices[i] = getPointOnCurveNaiveIndex(polylineTimes[i]);

      if (i > 0) {
        d = polylinePoints[i].get();
        d.sub(polylinePoints[i - 1]);
        polylineLengths[i - 1] = d.mag();
        polylineLength += d.mag();

        if (prevPolylineControlIndex < polylineControlIndex) {
          segmentLengths[polylineControlIndex] = d.mag();
        } else {
          segmentLengths[polylineControlIndex] += d.mag();
        }
        prevPolylineControlIndex = polylineControlIndex;
      } else {
        polylineLengths[i] = 0;
      }
    }
  }
}

