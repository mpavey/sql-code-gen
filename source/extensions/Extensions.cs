using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Data;
using System.ComponentModel;
using System.Text.RegularExpressions;
using System.Collections.Concurrent;

namespace Sandbox.Utilities
{
    public static class Extensions
    {
        private static ConcurrentDictionary<Type, IList<PropertyInfo>> typeDictionary = new ConcurrentDictionary<Type, IList<PropertyInfo>>();

        public static IList<PropertyInfo> GetPropertiesForType<T>()
        {
            //variables
            var type = typeof(T);

            //add to dictionary
            typeDictionary.TryAdd(type, type.GetProperties().ToList());

            //return
            return typeDictionary[type];
        }

        public static T ToObject<T>(this DataRow row) where T : new()
        {
            // variables
            IList<PropertyInfo> properties = GetPropertiesForType<T>();

            // return
            return CreateItemFromRow<T>(row, properties);
        }

        public static IList<T> ToList<T>(this DataTable table) where T : new()
        {
            // variables
            IList<T> result = new List<T>();

            // foreach
            foreach (DataRow row in table.Rows)
            {
                result.Add(row.ToObject<T>());
            }

            // return
            return result;
        }

        private static T CreateItemFromRow<T>(DataRow row, IList<PropertyInfo> properties) where T : new()
        {
            // variables
            T item = new T();

            // foreach
            foreach (var property in properties)
            {
                // make sure a column exists in the table with this property name
                if (row.Table.Columns.Contains(property.Name))
                {
                    // get the value from the current data row
                    object value = row[property.Name];

                    // set property accordingly
                    if (value != null & value != DBNull.Value)
                    {
                        SetProperty<T>(item, property.Name, value);
                    }
                }
            }

            // return
            return item;
        }

        public static string GetProperty<T>(this T obj, string Property)
        {
            // reflection
            PropertyInfo propertyInfo = obj.GetType().GetProperty(Property, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
            object property = null;

            // make sure property is valid
            if (propertyInfo != null)
            {
                property = propertyInfo.GetValue(obj, null);
            }

            // return value
            if (property != null)
            {
                return property.ToString();
            }
            else
            {
                return string.Empty;
            }
        }

        public static T SetProperty<T>(this T obj, string Property, object Value)
        {
            // reflection
            PropertyInfo prop = obj.GetType().GetProperty(Property, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);

            // trim strings
            if (Value.GetType() == typeof(string))
            {
                Value = Value.ToString().Trim();
            }

            // make sure property is valid
            if (prop != null && prop.CanWrite)
            {
                prop.SetValue(obj, Value, null);
            }

            // return
            return obj;
        }

        public static DataTable ToDataTable<T>(this IList<T> data)
        {
            // variables
            PropertyDescriptorCollection Properties = TypeDescriptor.GetProperties(typeof(T));
            object[] values = new object[Properties.Count];
            DataTable DT = new DataTable();

            // columns
            foreach (PropertyDescriptor PropertyInfo in Properties)
            {
                // data column
                DataColumn DataColumn = new DataColumn();

                // name
                DataColumn.ColumnName = PropertyInfo.Name;

                // data type
                if (PropertyInfo.PropertyType.Name.Contains("Nullable"))
                {
                    DataColumn.DataType = typeof(String);
                }
                else
                {
                    DataColumn.DataType = PropertyInfo.PropertyType;
                }

                // add to table
                DT.Columns.Add(DataColumn);
            }

            //for (int i = 0; i < Properties.Count; i++)
            //{
            //    PropertyDescriptor prop = Properties[i];
            //    DT.Columns.Add(prop.Name, prop.PropertyType);
            //}

            // rows
            foreach (T item in data)
            {
                for (int i = 0; i < values.Length; i++)
                {
                    values[i] = Properties[i].GetValue(item);
                }
                DT.Rows.Add(values);
            }

            // return
            return DT;
        }

        public static bool HasValue(this string Value)
        {
            return !Value.IsBlank();
        }

        public static bool IsBlank(this string Value)
        {
            bool ReturnValue = true;

            if (Value != null)
            {
                ReturnValue = Value.Trim().Length == 0;
            }

            return ReturnValue;
        }

        public static bool IsEqual(this string Value, string CompareValue)
        {
            bool ReturnValue = false;

            if (Value != null && CompareValue != null)
            {
                ReturnValue = string.Compare(Value.Trim(), CompareValue.Trim(), StringComparison.OrdinalIgnoreCase) == 0;
            }

            return ReturnValue;
        }

        public static bool IsEqual(this string Value, params string[] CompareValues)
        {
            if (Value != null && CompareValues != null)
            {
                foreach (string CompareValue in CompareValues)
                {
                    if (Value.IsEqual(CompareValue))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public static bool ContainsValue(this string Value, string CompareValue)
        {
            bool ReturnValue = false;

            if (Value != null && CompareValue != null)
            {
                ReturnValue = Value.Trim().IndexOf(CompareValue.Trim(), StringComparison.OrdinalIgnoreCase) >= 0;
            }

            return ReturnValue;
        }

        public static bool ContainsValue(this string Value, params string[] CompareValues)
        {
            if (Value != null && CompareValues != null)
            {
                foreach (string CompareValue in CompareValues)
                {
                    if (Value.ContainsValue(CompareValue))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public static bool StartsWithValue(this string Value, string CompareValue)
        {
            bool ReturnValue = false;

            if (Value != null && CompareValue != null)
            {
                ReturnValue = Value.Trim().StartsWith(CompareValue.Trim(), StringComparison.OrdinalIgnoreCase);
            }

            return ReturnValue;
        }

        public static bool StartsWithValue(this string Value, params string[] CompareValues)
        {
            if (Value != null && CompareValues != null)
            {
                foreach (string CompareValue in CompareValues)
                {
                    if (Value.StartsWithValue(CompareValue))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public static string ReplaceValue(this string Value, string Pattern, string Replacement)
        {
            return Regex.Replace(Value, Regex.Escape(Pattern), Replacement, RegexOptions.IgnoreCase);
        }
    }
}
