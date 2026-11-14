using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace HzBimNavisPlugin.Dashboard.Config
{
    // Dashboard definition model. One DashboardConfig = one Power BI report (.pbit) built from
    // the open Navisworks model. Stored in the per-project registry (DashboardRegistry) and
    // shipped as Templates/DefaultDashboard.json. Property names are the JSON names.

    /// <summary>One dashboard: pages of visuals, the 3D viewer settings and the export options.</summary>
    public sealed class DashboardConfig
    {
        public int SchemaVersion { get; set; } = 1;
        public string Id { get; set; } = Guid.NewGuid().ToString("N");
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        /// <summary>"default" (from the built-in template) or "custom".</summary>
        public string Origin { get; set; } = "custom";
        public DateTime CreatedUtc { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedUtc { get; set; } = DateTime.UtcNow;
        public List<PageSpec> Pages { get; set; } = new List<PageSpec>();
        public ViewerSettings Viewer { get; set; } = new ViewerSettings();
        public ExportOptions Export { get; set; } = new ExportOptions();
        /// <summary>Result of the last export (files, hashes). Null until exported once.</summary>
        public ExportState? LastExport { get; set; }

        /// <summary>Deep copy through JSON, so nested lists are never shared.</summary>
        public DashboardConfig Clone() =>
            JsonConvert.DeserializeObject<DashboardConfig>(JsonConvert.SerializeObject(this, DashboardJson.Settings), DashboardJson.Settings)!;
    }

    /// <summary>One report page.</summary>
    public sealed class PageSpec
    {
        public string Id { get; set; } = Guid.NewGuid().ToString("N").Substring(0, 8);
        public string Name { get; set; } = "";
        /// <summary>Show the 3D model viewer on this page (also needs Viewer.Enabled).</summary>
        public bool ShowViewer { get; set; } = true;
        public List<VisualSpec> Visuals { get; set; } = new List<VisualSpec>();
    }

    /// <summary>One visual on a page. Type is a VisualCatalog key (card, bar, donut, slicer, table, text...).</summary>
    public sealed class VisualSpec
    {
        public string Id { get; set; } = "v" + Guid.NewGuid().ToString("N").Substring(0, 8);
        public string Type { get; set; } = "";
        public string Title { get; set; } = "";
        /// <summary>Role name (Values, Category, Y...) → fields like "Elements.Category" or "Clashes.[Clash Count]".</summary>
        public Dictionary<string, List<string>> Fields { get; set; } =
            new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

        /// <summary>Optional manual placement in report pixels. All four set = placed exactly; otherwise auto-layout.</summary>
        public int? X { get; set; }
        public int? Y { get; set; }
        public int? Width { get; set; }
        public int? Height { get; set; }

        [JsonIgnore]
        public bool HasExplicitPosition => X.HasValue && Y.HasValue && Width.HasValue && Height.HasValue;
    }

    /// <summary>The embedded HZ-BIM 3D viewer visual.</summary>
    public sealed class ViewerSettings
    {
        public bool Enabled { get; set; } = true;
        public bool HideUnselected { get; set; } = false;
        public double GhostOpacity { get; set; } = 0.12;
        public string BackgroundColor { get; set; } = "#121117";
        /// <summary>Elements column used to colour the model (Category, Discipline, Model...).</summary>
        public string ColorBy { get; set; } = "Category";
    }

    /// <summary>What to extract and how the report is refreshed.</summary>
    public sealed class ExportOptions
    {
        /// <summary>"full" (every model) or "selection" (current selection / SelectionSet).</summary>
        public string Scope { get; set; } = "full";
        /// <summary>Selection/search set name used when Scope is "selection".</summary>
        public string SelectionSet { get; set; } = "";
        /// <summary>"pbit" (local template). Service publishing is not implemented yet.</summary>
        public string Format { get; set; } = "pbit";
        /// <summary>"live" (CSVs refreshed in place, report kept) or "static" (timestamped snapshot).</summary>
        public string RefreshMode { get; set; } = "live";
        /// <summary>Empty = the project's default dashboards folder.</summary>
        public string OutputFolder { get; set; } = "";
        public bool IncludeGeometry { get; set; } = true;
        public bool IncludeClashes { get; set; } = true;
        /// <summary>Navisworks property tabs exported to the Properties table.</summary>
        public List<string> PropertyTabs { get; set; } = new List<string> { "Element" };
        public int MaxPropertiesPerElement { get; set; } = 200;
    }

    /// <summary>Recorded after each export; drives the "data only vs regenerate" decision.</summary>
    public sealed class ExportState
    {
        public DateTime ExportedUtc { get; set; }
        public string PbitPath { get; set; } = "";
        public string DataFolder { get; set; } = "";
        public string DataHash { get; set; } = "";
        public string LayoutHash { get; set; } = "";
        public int ElementCount { get; set; }
        public int GeometryRows { get; set; }
        public int ClashCount { get; set; }
    }

    /// <summary>Shared JSON settings for dashboard definitions and the registry file.</summary>
    public static class DashboardJson
    {
        public static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            Formatting = Formatting.Indented,
            // Replace (not merge into) list/object defaults, so loading JSON never duplicates
            // default entries such as PropertyTabs = ["Element"].
            ObjectCreationHandling = ObjectCreationHandling.Replace,
            MissingMemberHandling = MissingMemberHandling.Ignore,
            NullValueHandling = NullValueHandling.Ignore,
            DateTimeZoneHandling = DateTimeZoneHandling.Utc,
        };
    }
}
